package dev.aster.geocam

import android.content.ContentValues
import android.graphics.*
import android.media.ExifInterface
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "media_store"
    private val executor = Executors.newFixedThreadPool(4)
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "processAndSaveImage" -> {
                        val inputPath = call.argument<String>("inputPath") ?: ""
                        val name = call.argument<String>("name") ?: "IMG_${System.currentTimeMillis()}.jpg"
                        val filter = call.argument<String>("filter") ?: "none"
                        val aspectRatio = call.argument<Double>("aspectRatio") ?: (3.0 / 4.0)
                        val whiteFrame = call.argument<Boolean>("whiteFrame") ?: false
                        val autoRotate = call.argument<Boolean>("autoRotate") ?: true
                        val geocamOn = call.argument<Boolean>("geocamOn") ?: true
                        val location = call.argument<String>("location") ?: ""
                        val address = call.argument<String>("address") ?: ""
                        val latLng = call.argument<String>("latLng") ?: ""
                        val dateTime = call.argument<String>("dateTime") ?: ""

                        executor.execute {
                            try {
                                val success = processAndSave(
                                    inputPath = inputPath,
                                    name = name,
                                    filter = filter,
                                    aspectRatio = aspectRatio,
                                    whiteFrame = whiteFrame,
                                    autoRotate = autoRotate,
                                    geocamOn = geocamOn,
                                    location = location,
                                    address = address,
                                    latLng = latLng,
                                    dateTime = dateTime
                                )

                                mainHandler.post {
                                    if (success) {
                                        result.success(mapOf("success" to true))
                                    } else {
                                        result.error("PROCESS_FAILED", "Failed to process and save image", null)
                                    }
                                }
                            } catch (e: Exception) {
                                e.printStackTrace()
                                mainHandler.post {
                                    result.error("ERROR", e.localizedMessage ?: "Unknown error", null)
                                }
                            }
                        }
                    }
                    "saveImage" -> {
                        val bytes = call.argument<ByteArray>("bytes")!!
                        val name = call.argument<String>("name")!!

                        executor.execute {
                            try {
                                val values = ContentValues().apply {
                                    put(MediaStore.Images.Media.DISPLAY_NAME, name)
                                    put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                                    put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/GeoCam")
                                }

                                val uri = contentResolver.insert(
                                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                                    values
                                )

                                if (uri != null) {
                                    contentResolver.openOutputStream(uri)?.use {
                                        it.write(bytes)
                                    }
                                    mainHandler.post { result.success(true) }
                                } else {
                                    mainHandler.post {
                                        result.error("SAVE_FAILED", "MediaStore insert failed", null)
                                    }
                                }
                            } catch (e: Exception) {
                                mainHandler.post {
                                    result.error("ERROR", e.localizedMessage, null)
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun processAndSave(
        inputPath: String,
        name: String,
        filter: String,
        aspectRatio: Double,
        whiteFrame: Boolean,
        autoRotate: Boolean,
        geocamOn: Boolean,
        location: String,
        address: String,
        latLng: String,
        dateTime: String
    ): Boolean {
        val inputFile = File(inputPath)
        if (!inputFile.exists()) {
            return false
        }

        // 1. Decode original bitmap
        val originalBitmap = BitmapFactory.decodeFile(inputPath) ?: return false

        // 2. Handle Orientation
        val currentBitmap = if (autoRotate) {
            val exif = try { ExifInterface(inputPath) } catch (e: Exception) { null }
            val orientation = exif?.getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL
            ) ?: ExifInterface.ORIENTATION_NORMAL

            val rotationDegrees = when (orientation) {
                ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                else -> 0f
            }

            if (rotationDegrees != 0f) {
                val matrix = Matrix().apply { postRotate(rotationDegrees) }
                val rotated = Bitmap.createBitmap(
                    originalBitmap,
                    0,
                    0,
                    originalBitmap.width,
                    originalBitmap.height,
                    matrix,
                    true
                )
                if (rotated != originalBitmap) originalBitmap.recycle()
                rotated
            } else {
                originalBitmap
            }
        } else {
            originalBitmap
        }

        // 3. Crop to target Aspect Ratio
        val curW = currentBitmap.width
        val curH = currentBitmap.height
        val currentRatio = curW.toDouble() / curH.toDouble()

        val croppedBitmap = if (Math.abs(currentRatio - aspectRatio) > 0.01) {
            val targetW: Int
            val targetH: Int
            val cropX: Int
            val cropY: Int

            if (currentRatio > aspectRatio) {
                targetH = curH
                targetW = Math.min((curH * aspectRatio).toInt(), curW)
                cropX = Math.max((curW - targetW) / 2, 0)
                cropY = 0
            } else {
                targetW = curW
                targetH = Math.min((curW / aspectRatio).toInt(), curH)
                cropX = 0
                cropY = Math.max((curH - targetH) / 2, 0)
            }

            val safeW = targetW.coerceIn(1, curW - cropX)
            val safeH = targetH.coerceIn(1, curH - cropY)

            val cropped = Bitmap.createBitmap(currentBitmap, cropX, cropY, safeW, safeH)
            if (cropped != currentBitmap) currentBitmap.recycle()
            cropped
        } else {
            currentBitmap
        }

        val baseW = croppedBitmap.width
        val baseH = croppedBitmap.height

        // 4. Create Final Render Canvas with optional White Frame
        val frameWidth = if (whiteFrame) (baseW * 0.05).toInt() else 0
        val finalW = baseW + frameWidth * 2
        val finalH = baseH + frameWidth * 2

        val finalBitmap = Bitmap.createBitmap(finalW, finalH, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(finalBitmap)

        if (whiteFrame) {
            canvas.drawColor(Color.WHITE)
        }

        // 5. Setup Paint with Color Filter (Hardware/Native matrix)
        val photoPaint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        when (filter) {
            "mono" -> {
                val matrix = ColorMatrix().apply { setSaturation(0f) }
                photoPaint.colorFilter = ColorMatrixColorFilter(matrix)
            }
            "sepia" -> {
                val matrix = ColorMatrix().apply {
                    setSaturation(0f)
                    val sepia = ColorMatrix().apply {
                        setScale(1.0f, 0.95f, 0.82f, 1.0f)
                    }
                    postConcat(sepia)
                }
                photoPaint.colorFilter = ColorMatrixColorFilter(matrix)
            }
            "vintage" -> {
                val matrix = ColorMatrix(floatArrayOf(
                    1.08f, 0.0f, 0.0f, 0.0f, 16f,
                    0.0f, 1.02f, 0.0f, 0.0f, 8f,
                    0.0f, 0.0f, 0.85f, 0.0f, -8f,
                    0.0f, 0.0f, 0.0f, 1.0f, 0f
                ))
                photoPaint.colorFilter = ColorMatrixColorFilter(matrix)
            }
        }

        // Draw photo onto canvas
        canvas.drawBitmap(croppedBitmap, frameWidth.toFloat(), frameWidth.toFloat(), photoPaint)
        croppedBitmap.recycle()

        // 6. Draw Geotag Watermark Overlay if enabled
        if (geocamOn) {
            val photoLeft = frameWidth.toFloat()
            val photoTop = frameWidth.toFloat()
            val photoW = baseW.toFloat()
            val photoH = baseH.toFloat()

            val overlayH = photoH * 0.20f
            val overlayTop = photoTop + photoH - overlayH

            // Dark gradient overlay strip
            val gradientPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(
                    0f, overlayTop, 0f, photoTop + photoH,
                    intArrayOf(0x00000000, 0xB316131D.toInt(), 0xF216131D.toInt()),
                    floatArrayOf(0.0f, 0.25f, 1.0f),
                    Shader.TileMode.CLAMP
                )
            }
            canvas.drawRect(
                photoLeft, overlayTop,
                photoLeft + photoW, photoTop + photoH,
                gradientPaint
            )

            // Pastel accent line
            val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(
                    photoLeft + photoW * 0.08f, photoTop + photoH - 6f,
                    photoLeft + photoW * 0.92f, photoTop + photoH - 6f,
                    intArrayOf(0xFFFFB5C5.toInt(), 0xFFD6C7FF.toInt(), 0xFFBAE1FF.toInt()),
                    null, Shader.TileMode.CLAMP
                )
                strokeWidth = (photoH * 0.004f).coerceIn(2.0f, 6.0f)
            }
            val lineY = photoTop + photoH - (photoH * 0.012f)
            canvas.drawLine(
                photoLeft + photoW * 0.08f, lineY,
                photoLeft + photoW * 0.92f, lineY,
                linePaint
            )

            // Draw clean typography text
            val textLeft = photoLeft + photoW * 0.08f
            val maxTextWidth = photoW * 0.84f

            val titleSize = photoH * 0.038f
            val bodySize = photoH * 0.026f
            val metaSize = photoH * 0.022f

            var curY = overlayTop + (overlayH * 0.28f)

            if (location.isNotEmpty()) {
                drawText(canvas, location, titleSize, 0xFFFAF7FC.toInt(), true, textLeft, curY, maxTextWidth)
                curY += titleSize * 1.25f
            }

            if (address.isNotEmpty()) {
                drawText(canvas, address, bodySize, 0xFFE8E3EE.toInt(), false, textLeft, curY, maxTextWidth)
                curY += bodySize * 1.20f
            }

            if (latLng.isNotEmpty()) {
                drawText(canvas, latLng, metaSize, 0xFFD6C7FF.toInt(), false, textLeft, curY, maxTextWidth)
                curY += metaSize * 1.15f
            }

            if (dateTime.isNotEmpty()) {
                drawText(canvas, dateTime, metaSize, 0xFFB5EAD7.toInt(), false, textLeft, curY, maxTextWidth)
            }
        }

        // 7. Compress & Save directly to MediaStore
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, name)
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/GeoCam")
        }

        val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
        var saved = false
        if (uri != null) {
            contentResolver.openOutputStream(uri)?.use { out ->
                saved = finalBitmap.compress(Bitmap.CompressFormat.JPEG, 95, out)
            }
        }

        finalBitmap.recycle()

        // Clean up temporary camera capture file
        try {
            inputFile.delete()
        } catch (_: Exception) {}

        return saved
    }

    private fun drawText(
        canvas: Canvas,
        text: String,
        size: Float,
        color: Int,
        isBold: Boolean,
        x: Float,
        y: Float,
        maxWidth: Float
    ) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = size
            this.color = color
            typeface = if (isBold) Typeface.create(Typeface.DEFAULT, Typeface.BOLD) else Typeface.DEFAULT
            letterSpacing = 0.02f
        }

        val measuredWidth = paint.measureText(text)
        val displayText = if (measuredWidth > maxWidth) {
            val count = paint.breakText(text, true, maxWidth - paint.measureText("..."), null)
            text.substring(0, count) + "..."
        } else {
            text
        }

        val fontMetrics = paint.fontMetrics
        val baseline = y - fontMetrics.ascent
        canvas.drawText(displayText, x, baseline, paint)
    }
}
