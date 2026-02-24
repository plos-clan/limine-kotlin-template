import kotlin.experimental.ExperimentalNativeApi
import kotlinx.cinterop.*
import limine.executable_file_request
import limine.framebuffer_request
import limine.limine_framebuffer

@ExperimentalNativeApi
@ExperimentalForeignApi
@CName("kernel_main")
fun kernelMain(): Nothing {
    framebuffer_request.response?.pointed?.let {
        if (it.framebuffer_count > 0u) {
            it.framebuffers?.get(0)?.let(::paintDemo)
        }
    }

    while (true) {}
}

@ExperimentalForeignApi
private fun paintDemo(fbPointer: CPointer<limine_framebuffer>) {
    val fb = fbPointer.pointed

    if (fb.bpp.toInt() != 32) return
    val pixels = fb.address?.reinterpret<UIntVar>() ?: return

    val width = fb.width.toInt()
    val height = fb.height.toInt()
    val stride = (fb.pitch / 4UL).toInt()

    for (y in 0 until height) {
        val colorY = (y * 255 / height) shl 8 
        val rowOffset = y * stride

        for (x in 0 until width) {
            val colorX = (x * 255 / width) shl 16
            pixels[rowOffset + x] = (colorX or colorY).toUInt()
        }
    }
}
