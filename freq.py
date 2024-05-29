min_period = 8 * 256

base_frequency = 33143.9 / 8.0
i = 0

periods = []

while True:
    frequency = 27.5 * (2.0**(i/12.0))

    period = int(0.5 + 256 * base_frequency / frequency)
    if period < min_period:
        break

    periods.append(period)

    i += 1

print(
    'PeriodsLo: .byte '
    + ','.join(
        str(period & 0xff)
        for period in periods
    )
)

print(
    'PeriodsHi: .byte '
    + ','.join(
        str(period >> 8)
        for period in periods
    )
)

print('PERIOD_COUNT=' + str(len(periods)))