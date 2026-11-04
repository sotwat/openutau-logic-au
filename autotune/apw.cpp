#include <cstddef>
#include "hsp3.h"
#include <CommonCrypto/CommonDigest.h>
#include <array>
#include <cstdio>
#include <fstream>
#include <iterator>
#include <vector>

static char selection[] = "selection.tmp";
static char bytecode[] = "start.ax";
static bool started;

char *hsp3ext_getdir(int) { return selection; }
void hsp3win_dialog(char *message) { std::fprintf(stderr, "%s\n", message); }

static void *systemValue(int *type, int opcode) {
    if (opcode != 0x102) throw HSPERR_UNSUPPORTED_FUNCTION;
    code_next();
    if (code_geti() != 4) throw HSPERR_UNSUPPORTED_FUNCTION;
    code_next();
    *type = HSPVAR_FLAG_STR;
    return selection;
}

static int windowCommand(int opcode) {
    // The first clrobj follows settings initialization; 5533 is the Run button handler.
    if (opcode == 0x30 && code_getpcbak() == code_getctx()->mem_mcs + 1828 && !started) {
        started = true;
        code_setpc(code_getctx()->mem_mcs + 5533);
        return 0;
    }
    switch (opcode) {
        case 0: case 0x0e: case 0x0f: case 0x10: case 0x11: case 0x14:
        case 0x16: case 0x1c: case 0x25: case 0x26: case 0x27: case 0x31:
            do { code_next(); } while (!(code_getexflg() & EXFLG_1));
            return 0;
        default:
            std::fprintf(stderr, "AutoPitchwriter window command: 0x%x\n", opcode);
            throw HSPERR_UNSUPPORTED_FUNCTION;
    }
}

static void message(HSPCTX *ctx) {
    if (ctx->runmode != RUNMODE_END) throw HSPERR_UNSUPPORTED_FUNCTION;
}

int main(int argc, char **argv) {
    if (argc != 2) return 64;
    std::ifstream source(argv[1], std::ios::binary);
    std::vector<unsigned char> exe(std::istreambuf_iterator<char>(source), {});
    constexpr size_t offset = 225328, length = 80190;
    if (exe.size() != offset + length) return 1;

    // Decode the embedded DPM entry as data. Never launch the Windows executable.
    unsigned char previous = 0;
    for (size_t i = offset; i < exe.size(); ++i) {
        previous = static_cast<unsigned char>(previous + (exe[i] ^ 166) - 4);
        exe[i] = previous;
    }
    constexpr std::array<unsigned char, 32> expected = {
        0xb4, 0x62, 0xb3, 0x57, 0x2e, 0xce, 0xb6, 0xa6, 0xdf, 0x0a, 0x4d, 0xa2, 0x77, 0xe7, 0x7b, 0x60,
        0xd1, 0x52, 0x7a, 0xfe, 0x3f, 0x7d, 0x97, 0xe2, 0xab, 0x72, 0x5e, 0xe2, 0x40, 0x95, 0xb4, 0x58,
    };
    std::array<unsigned char, 32> digest;
    CC_SHA256(exe.data() + offset, length, digest.data());
    if (digest != expected) {
        std::fputs("AutoPitchwriter bytecode checksum mismatch.\n", stderr);
        return 1;
    }
    std::ofstream out(bytecode, std::ios::binary | std::ios::trunc);
    out.write(reinterpret_cast<const char *>(exe.data() + offset), length);
    out.close();
    if (!out) return 1;

    Hsp3 hsp;
    hsp.SetFileName(bytecode);
    if (hsp.Reset(0)) return 1;
    hsp.SetCommandLinePrm(selection);
    hsp.hspctx.msgfunc = message;
    code_gettypeinfo(TYPE_EXTCMD)->cmdfunc = windowCommand;
    code_gettypeinfo(TYPE_EXTSYSVAR)->reffunc = systemValue;
    int result = code_execcmd();
    if (result == RUNMODE_END && started && code_geterror() == 0) return 0;
    std::fprintf(stderr, "AutoPitchwriter HSP error %d (word %td).\n",
        code_geterror(), code_getpcbak() - hsp.hspctx.mem_mcs);
    return 1;
}
