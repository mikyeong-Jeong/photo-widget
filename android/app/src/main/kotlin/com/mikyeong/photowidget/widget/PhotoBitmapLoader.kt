package com.mikyeong.photowidget.widget

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import java.io.File

/** 위젯 크기에 맞게 줄이고 사진 방향(EXIF)을 바로잡아 Bitmap 으로 읽는다. */
object PhotoBitmapLoader {
    /**
     * 위젯을 [targetWidth]×[targetHeight] px 로 꽉 채울 수 있는 가장 작은 크기로 읽되,
     * [maxBytes] 를 넘지 않게 한다. 파일이 없거나 읽을 수 없으면 null.
     */
    fun load(path: String, targetWidth: Int, targetHeight: Int, maxBytes: Long): Bitmap? {
        if (!File(path).exists()) return null

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        val orientation = readOrientation(path)
        val swapped = orientation.swapsAxes
        val needWidth = if (swapped) targetHeight else targetWidth
        val needHeight = if (swapped) targetWidth else targetHeight

        var sample = 1
        while (bounds.outWidth / (sample * 2) >= needWidth &&
            bounds.outHeight / (sample * 2) >= needHeight
        ) {
            sample *= 2
        }
        while (4L * (bounds.outWidth / sample) * (bounds.outHeight / sample) > maxBytes) {
            sample *= 2
        }

        val decoded =
            BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
                ?: return null
        if (orientation.matrix.isIdentity) return decoded

        val rotated =
            Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, orientation.matrix, true)
        if (rotated !== decoded) decoded.recycle()
        return rotated
    }

    /**
     * 긴 변이 [maxSide] px 이하가 되게 줄이고 사진 방향(EXIF)을 픽셀에 반영해 읽는다.
     * 앱에 저장할 사진을 만들 때 쓴다. 읽을 수 없으면 null.
     */
    fun loadFitting(path: String, maxSide: Int): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        val longest = maxOf(bounds.outWidth, bounds.outHeight)
        var sample = 1
        while (longest / (sample * 2) >= maxSide) sample *= 2
        val decoded =
            BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
                ?: return null

        val matrix = Matrix(readOrientation(path).matrix)
        val scale = maxSide.toFloat() / maxOf(decoded.width, decoded.height)
        if (scale < 1f) matrix.postScale(scale, scale)
        if (matrix.isIdentity) return decoded

        val result =
            Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, matrix, true)
        if (result !== decoded) decoded.recycle()
        return result
    }

    private class Orientation(val matrix: Matrix, val swapsAxes: Boolean)

    private fun readOrientation(path: String): Orientation {
        val value =
            try {
                ExifInterface(path).getAttributeInt(
                    ExifInterface.TAG_ORIENTATION,
                    ExifInterface.ORIENTATION_NORMAL,
                )
            } catch (_: Exception) {
                ExifInterface.ORIENTATION_NORMAL
            }
        val matrix = Matrix()
        when (value) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.postScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.postScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                matrix.postRotate(90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                matrix.postRotate(-90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
        }
        val swaps =
            value == ExifInterface.ORIENTATION_TRANSPOSE ||
                value == ExifInterface.ORIENTATION_ROTATE_90 ||
                value == ExifInterface.ORIENTATION_TRANSVERSE ||
                value == ExifInterface.ORIENTATION_ROTATE_270
        return Orientation(matrix, swaps)
    }
}
