#!/usr/bin/env python
#
# Copyright 2007 Jose Fonseca
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

def run(statement, filename=None, sort=-1):
    import os, tempfile, hotshot, hotshot.stats
    logfd, logfn = tempfile.mkstemp()
    prof = hotshot.Profile(logfn)
    try:
        prof = prof.run(statement)
    except SystemExit:
        pass
    try:
        try:
            prof = prof.run(statement)
        except SystemExit:
            pass
        prof.close()
    finally:
        stats = hotshot.stats.load(logfn)
        stats.strip_dirs()
        stats.sort_stats(sort)
        if filename is not None:
            result = stats.dump_stats(filename)
        else:
            result = stats.print_stats()
        os.unlink(logfn)
    return result

def main():
    import os, sys
    from optparse import OptionParser
    usage = "hotshotmain.py [-o output_file_path] [-s sort] scriptfile [arg] ..."
    parser = OptionParser(usage=usage)
    parser.allow_interspersed_args = False
    parser.add_option('-o', '--outfile', dest="outfile",
        help="Save stats to <outfile>", default=None)
    parser.add_option('-s', '--sort', dest="sort",
        help="Sort order when printing to stdout, based on pstats.Stats class", default=-1)

    if not sys.argv[1:]:
        parser.print_usage()
        sys.exit(2)

    (options, args) = parser.parse_args()
    sys.argv[:] = args

    if (len(sys.argv) > 0):
        sys.path.insert(0, os.path.dirname(sys.argv[0]))
        run('execfile(%r)' % (sys.argv[0],), options.outfile, options.sort)
    else:
        parser.print_usage()
    return parser

if __name__ == "__main__":
    main()
