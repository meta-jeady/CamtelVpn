package com.dxstunnel.dxs_tunnel

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Bundle

import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Statistics
import com.wireguard.android.backend.Tunnel
import com.wireguard.config.Config

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

import java.io.ByteArrayInputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors


class MainActivity :
    FlutterActivity(),
    MethodChannel.MethodCallHandler {

    companion object {

        private const val CHANNEL =
            "dxs_tunnel/wireguard"

        private const val VPN_PERMISSION_REQUEST =
            4001
    }


    private lateinit var channel:
        MethodChannel

    private lateinit var backend:
        GoBackend

    private val executor:
        ExecutorService =
            Executors.newSingleThreadExecutor()


    private var tunnel:
        DxsTunnel? = null

    private var pendingName:
        String? = null

    private var pendingConfig:
        String? = null

    private var pendingResult:
        MethodChannel.Result? = null


    override fun onCreate(
        savedInstanceState: Bundle?
    ) {
        super.onCreate(savedInstanceState)

        backend =
            GoBackend(applicationContext)

        channel =
            MethodChannel(
                flutterEngine!!
                    .dartExecutor
                    .binaryMessenger,
                CHANNEL
            )

        channel.setMethodCallHandler(this)
    }


    override fun onDestroy() {

        channel.setMethodCallHandler(null)

        executor.shutdown()

        super.onDestroy()
    }


    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {

        when (call.method) {

            "connect" -> connect(
                call,
                result
            )

            "disconnect" -> disconnect(
                result
            )

            "status" -> status(
                result
            )

            "version" -> version(
                result
            )

            else ->
                result.notImplemented()
        }
    }


    private fun connect(
        call: MethodCall,
        result: MethodChannel.Result
    ) {

        val name =
            call.argument<String>("name")
                ?.trim()

        val configText =
            call.argument<String>("config")
                ?.trim()

        if (name.isNullOrEmpty()) {

            result.error(
                "INVALID_NAME",
                "Le nom du tunnel est vide.",
                null
            )

            return
        }


        if (configText.isNullOrEmpty()) {

            result.error(
                "INVALID_CONFIG",
                "La configuration est vide.",
                null
            )

            return
        }


        if (!configText.contains("[Interface]") ||
            !configText.contains("[Peer]")
        ) {

            result.error(
                "INVALID_CONFIG",
                "Configuration WireGuard invalide.",
                null
            )

            return
        }


        val permissionIntent =
            VpnService.prepare(this)


        if (permissionIntent != null) {

            pendingName =
                name

            pendingConfig =
                configText

            pendingResult =
                result

            startActivityForResult(
                permissionIntent,
                VPN_PERMISSION_REQUEST
            )

            return
        }


        startTunnel(
            name,
            configText,
            result
        )
    }


    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {

        super.onActivityResult(
            requestCode,
            resultCode,
            data
        )


        if (requestCode !=
            VPN_PERMISSION_REQUEST
        ) {
            return
        }


        val result =
            pendingResult

        val name =
            pendingName

        val config =
            pendingConfig


        pendingResult = null
        pendingName = null
        pendingConfig = null


        if (result == null ||
            name == null ||
            config == null
        ) {
            return
        }


        if (resultCode !=
            Activity.RESULT_OK
        ) {

            result.error(
                "VPN_PERMISSION_DENIED",
                "Permission VPN refusée.",
                null
            )

            return
        }


        startTunnel(
            name,
            config,
            result
        )
    }


    private fun startTunnel(
        name: String,
        configText: String,
        result: MethodChannel.Result
    ) {

        executor.execute {

            try {

                val config =
                    Config.parse(
                        ByteArrayInputStream(
                            configText
                                .toByteArray(
                                    Charsets.UTF_8
                                )
                        )
                    )


                if (tunnel == null ||
                    tunnel?.name != name
                ) {

                    if (tunnel != null) {

                        try {

                            backend.setState(
                                tunnel!!,
                                Tunnel.State.DOWN,
                                null
                            )

                        } catch (_: Exception) {
                        }
                    }


                    tunnel =
                        DxsTunnel(
                            name
                        )
                }


                val currentTunnel =
                    tunnel!!


                backend.setState(
                    currentTunnel,
                    Tunnel.State.UP,
                    config
                )


                runOnUiThread {

                    result.success(
                        mapOf(
                            "connected" to true,
                            "state" to "UP"
                        )
                    )
                }

            } catch (
                error: Exception
            ) {

                runOnUiThread {

                    result.error(
                        "VPN_ERROR",
                        error.message
                            ?: "Impossible de démarrer le VPN.",
                        null
                    )
                }
            }
        }
    }


    private fun disconnect(
        result: MethodChannel.Result
    ) {

        executor.execute {

            try {

                val currentTunnel =
                    tunnel


                if (currentTunnel != null) {

                    backend.setState(
                        currentTunnel,
                        Tunnel.State.DOWN,
                        null
                    )
                }


                runOnUiThread {

                    result.success(
                        mapOf(
                            "connected" to false,
                            "state" to "DOWN"
                        )
                    )
                }

            } catch (
                error: Exception
            ) {

                runOnUiThread {

                    result.error(
                        "VPN_ERROR",
                        error.message
                            ?: "Impossible d'arrêter le VPN.",
                        null
                    )
                }
            }
        }
    }


    private fun status(
        result: MethodChannel.Result
    ) {

        executor.execute {

            try {

                val currentTunnel =
                    tunnel


                if (currentTunnel == null) {

                    runOnUiThread {

                        result.success(
                            disconnectedStatus()
                        )
                    }

                    return@execute
                }


                val state =
                    backend.getState(
                        currentTunnel
                    )


                val statistics:
                    Statistics =
                    backend.getStatistics(
                        currentTunnel
                    )


                val connected =
                    state ==
                        Tunnel.State.UP


                runOnUiThread {

                    result.success(
                        mapOf(
                            "connected" to connected,
                            "state" to state.name,
                            "downloadBytes" to
                                statistics.totalRx(),
                            "uploadBytes" to
                                statistics.totalTx()
                        )
                    )
                }

            } catch (_: Exception) {

                runOnUiThread {

                    result.success(
                        disconnectedStatus()
                    )
                }
            }
        }
    }


    private fun version(
        result: MethodChannel.Result
    ) {

        executor.execute {

            try {

                val version =
                    backend.version

                runOnUiThread {

                    result.success(
                        version
                    )
                }

            } catch (
                error: Exception
            ) {

                runOnUiThread {

                    result.error(
                        "VERSION_ERROR",
                        error.message,
                        null
                    )
                }
            }
        }
    }


    private fun disconnectedStatus():
        Map<String, Any> {

        return mapOf(
            "connected" to false,
            "state" to "DOWN",
            "downloadBytes" to 0L,
            "uploadBytes" to 0L
        )
    }


    private class DxsTunnel(
        private val tunnelName:
            String
    ) : Tunnel {

        var currentState:
            Tunnel.State =
            Tunnel.State.DOWN


        override fun getName():
            String {

            return tunnelName
        }


        override fun onStateChange(
            newState:
                Tunnel.State
        ) {

            currentState =
                newState
        }
    }
    }
