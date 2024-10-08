namespace Musys.GLibC {
    [CCode (cname="backtrace", cheader_filename="execinfo.h")]
    public extern int backtrace(pointer []stack_buffer);

    [CCode (cname="backtrace_symbols", cheader_filename="execinfo.h")]
    public extern string *backtrace_symbols(pointer []stack_buffer);

    [CCode (cname="backtrace_symbols_fd", cheader_filename="execinfo.h")]
    public extern void backtrace_symbols_fd(pointer *stack_buffer, int len, int fd);
}

namespace Musys {
    [CCode (has_type_id=false)]
    public struct SourceLocation {
        unowned string filename;
        unowned string method;
        int            line;

        [CCode (cname="__LINE__")]
        public extern const int    CLINE;
        [CCode (cname="__func__")]
        public extern const string CFUNC;
        [CCode (cname="__FILE__")]
        public extern const string CFILE;

        public SourceLocation.current(string filename = Musys.SourceLocation.CFILE,
                                      string method   = Musys.SourceLocation.CFUNC,
                                      int    line     = Musys.SourceLocation.CLINE) {
            this.filename = filename;
            this.method   = method;
            this.line     = line;
        }
    }

    public enum ErrLevel {
        INFO, DEBUG, WARNING, CRITICAL, FATAL;
    }
    public errordomain RuntimeErr {
        /** 数组下标越界 */
        INDEX_OVERFLOW,
        NULL_PTR;
    }

    public inline int print_backtrace()
    {
        pointer stack_buffer[32];
        int ret_nlayers = GLibC.backtrace(stack_buffer);
        GLibC.backtrace_symbols_fd((pointer*)stack_buffer, ret_nlayers, 2);
        return ret_nlayers;
    }

    private void _crash_print_head(ref SourceLocation loc)
    {
        stderr.printf("|================ [进程 %d 已崩溃] ================|\n",
                      stdc.getpid());
        stderr.puts  ("-----------------<  位置  >-----------------\n");
        stderr.printf("源文件: %s\n行:   %d\n方法: %s\n", loc.filename, loc.line, loc.method);
        stderr.puts  ("-----------------< 栈回溯 >-----------------\n");
        print_backtrace();
    }

    /**
     * 打印栈回溯, 然后报错崩溃. 一般与 critical() 函数配合使用.
     */
    [NoReturn]
    public void traced_abort()
    {
        stderr.printf("|================ [进程 %d 已崩溃] ================|\n",
                      stdc.getpid());
        print_backtrace();
        Process.abort();
    }

    [NoReturn]
    public void crash(string msg, bool pauses = true, SourceLocation loc = SourceLocation.current())
    {
        _crash_print_head(ref loc);
        stderr.puts("-----------------<  消息  >-----------------\n");
        stderr.puts(msg);
        if (pauses) {
            stderr.puts("请按回车键继续...");
            stdin.getc();
        }
        Process.abort();
    }
    [NoReturn]
    public inline void crash_vfmt(SourceLocation loc, string fmt, va_list ap)
    {
        _crash_print_head(ref loc);
        stderr.puts("-----------------<  消息  >-----------------\n");
        stderr.vprintf(fmt, ap);
        stderr.puts("\n请按回车键继续...");
        stdin.getc();
        Process.abort();
    }
    [NoReturn, PrintfFormat]
    public void crash_fmt(SourceLocation loc, string fmt, ...) {
        crash_vfmt(loc, fmt, va_list());
    }
}