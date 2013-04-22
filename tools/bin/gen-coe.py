#!/usr/bin/env python

import sys
import subprocess
import tempfile

if len(sys.argv) != 2:
    print 'Usage:', sys.argv[0], '<ELF file>'
    exit(1)

in_file = sys.argv[1]
bin_file = tempfile.mkstemp()[1]

try:
    args = ['msp430-objcopy', '-O', 'binary', in_file, bin_file]
    print ' '.join(args)
    subprocess.check_call(args)
except Exception as e:
    print e
    exit(1)

low_file = in_file + '-low.coe'
high_file = in_file + '-high.coe'

try:
    with open(bin_file, 'r') as f:
        with open(low_file, 'w') as fl:
            with open(high_file, 'w') as fh:
                header = 'MEMORY_INITIALIZATION_RADIX=16;\n' + \
                         'MEMORY_INITIALIZATION_VECTOR=\n'
                fl.write(header)
                fh.write(header)
                contents = f.read()
                fcurrent = fl
                fnext = fh

                for byte in contents:
                    fcurrent.write(byte.encode('hex') + ',\n')
                    fcurrent, fnext = fnext, fcurrent

                for f in [fl, fh]:
                    f.seek(-2, 1)
                    f.write(';')
except Exception as e:
    print e
    exit(1)
