int get_nprocs(void) {
    return 1;
}

int __fxstat(int version, int fd, void *statbuf) {
    (void)version;
    (void)fd;
    (void)statbuf;
    return -1;
}

int isnan(double x) {
    union {
        double f64;
        unsigned long long u64;
    } bits;
    bits.f64 = x;
    return (bits.u64 & 0x7ff0000000000000ULL) == 0x7ff0000000000000ULL
        && (bits.u64 & 0x000fffffffffffffULL) != 0;
}

int __unorddf2(double a, double b) {
    union { double f; unsigned long long u; } ua = {a}, ub = {b};
    unsigned long long ea = (ua.u >> 52) & 0x7ff;
    unsigned long long ma = ua.u & 0x000fffffffffffffULL;
    unsigned long long eb = (ub.u >> 52) & 0x7ff;
    unsigned long long mb = ub.u & 0x000fffffffffffffULL;
    return (ea == 0x7ff && ma) || (eb == 0x7ff && mb);
}
