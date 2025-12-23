#!/usr/bin/env python
#
# Copyright 2008-2009 Jose Fonseca
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

"""Generate a dot graph from the output of several profilers."""

__author__ = "Jose Fonseca et al"


import sys
import math
import os.path
import re
import textwrap
import optparse
import xml.parsers.expat
import collections
import locale


# Python 2.x/3.x compatibility
if sys.version_info[0] >= 3:
    PYTHON_3 = True
    def compat_iteritems(x): return x.items()  # No iteritems() in Python 3
    def compat_itervalues(x): return x.values()  # No itervalues() in Python 3
    def compat_keys(x): return list(x.keys())  # keys() is a generator in Python 3
    basestring = str  # No class basestring in Python 3
    unichr = chr # No unichr in Python 3
    xrange = range # No xrange in Python 3
else:
    PYTHON_3 = False
    def compat_iteritems(x): return x.iteritems()
    def compat_itervalues(x): return x.itervalues()
    def compat_keys(x): return x.keys()


try:
    # Debugging helper module
    import debug
except ImportError:
    pass


MULTIPLICATION_SIGN = unichr(0xd7)


def times(x):
    return "%u%s" % (x, MULTIPLICATION_SIGN)

def percentage(p):
    return "%.02f%%" % (p*100.0,)

def add(a, b):
    return a + b

def equal(a, b):
    if a == b:
        return a
    else:
        return None

def fail(a, b):
    assert False


tol = 2 ** -23

def ratio(numerator, denominator):
    try:
        ratio = float(numerator)/float(denominator)
    except ZeroDivisionError:
        # 0/0 is undefined, but 1.0 yields more useful results
        return 1.0
    if ratio < 0.0:
        if ratio < -tol:
            sys.stderr.write('warning: negative ratio (%s/%s)\n' % (numerator, denominator))
        return 0.0
    if ratio > 1.0:
        if ratio > 1.0 + tol:
            sys.stderr.write('warning: ratio greater than one (%s/%s)\n' % (numerator, denominator))
        return 1.0
    return ratio


class UndefinedEvent(Exception):
    """Raised when attempting to get an event which is undefined."""
    
    def __init__(self, event):
        Exception.__init__(self)
        self.event = event

    def __str__(self):
        return 'unspecified event %s' % self.event.name


class Event(object):
    """Describe a kind of event, and its basic operations."""

    def __init__(self, name, null, aggregator, formatter = str):
        self.name = name
        self._null = null
        self._aggregator = aggregator
        self._formatter = formatter

    def __eq__(self, other):
        return self is other

    def __hash__(self):
        return id(self)

    def null(self):
        return self._null

    def aggregate(self, val1, val2):
        """Aggregate two event values."""
        assert val1 is not None
        assert val2 is not None
        return self._aggregator(val1, val2)
    
    def format(self, val):
        """Format an event value."""
        assert val is not None
        return self._formatter(val)


CALLS = Event("Calls", 0, add, times)
SAMPLES = Event("Samples", 0, add, times)
SAMPLES2 = Event("Samples", 0, add, times)

# Count of samples where a given function was either executing or on the stack.
# This is used to calculate the total time ratio according to the
# straightforward method described in Mike Dunlavey's answer to
# stackoverflow.com/questions/1777556/alternatives-to-gprof, item 4 (the myth
# "that recursion is a tricky confusing issue"), last edited 2012-08-30: it's
# just the ratio of TOTAL_SAMPLES over the number of samples in the profile.
#
# Used only when totalMethod == callstacks
TOTAL_SAMPLES = Event("Samples", 0, add, times)

TIME = Event("Time", 0.0, add, lambda x: '(' + str(x) + ')')
TIME_RATIO = Event("Time ratio", 0.0, add, lambda x: '(' + percentage(x) + ')')
TOTAL_TIME = Event("Total time", 0.0, fail)
TOTAL_TIME_RATIO = Event("Total time ratio", 0.0, fail, percentage)

totalMethod = 'callratios'


class Object(object):
    """Base class for all objects in profile which can store events."""

    def __init__(self, events=None):
        if events is None:
            self.events = {}
        else:
            self.events = events

    def __hash__(self):
        return id(self)

    def __eq__(self, other):
        return self is other

    def __contains__(self, event):
        return event in self.events
    
    def __getitem__(self, event):
        try:
            return self.events[event]
        except KeyError:
            raise UndefinedEvent(event)
    
    def __setitem__(self, event, value):
        if value is None:
            if event in self.events:
                del self.events[event]
        else:
            self.events[event] = value


class Call(Object):
    """A call between functions.
    
    There should be at most one call object for every pair of functions.
    """

    def __init__(self, callee_id):
        Object.__init__(self)
        self.callee_id = callee_id
        self.ratio = None
        self.weight = None


class Function(Object):
    """A function."""

    def __init__(self, id, name):
        Object.__init__(self)
        self.id = id
        self.name = name
        self.module = None
        self.process = None
        self.calls = {}
        self.called = None
        self.weight = None
        self.cycle = None
    
    def add_call(self, call):
        if call.callee_id in self.calls:
            sys.stderr.write('warning: overwriting call from function %s to %s\n' % (str(self.id), str(call.callee_id)))
        self.calls[call.callee_id] = call

    def get_call(self, callee_id):
        if not callee_id in self.calls:
            call = Call(callee_id)
            call[SAMPLES] = 0
            call[SAMPLES2] = 0
            call[CALLS] = 0
            self.calls[callee_id] = call
        return self.calls[callee_id]

    _parenthesis_re = re.compile(r'\([^()]*\)')
    _angles_re = re.compile(r'<[^<>]*>')
    _const_re = re.compile(r'\s+const$')

    def stripped_name(self):
        """Remove extraneous information from C++ demangled function names."""

        name = self.name

        # Strip function parameters from name by recursively removing paired parenthesis
        while True:
            name, n = self._parenthesis_re.subn('', name)
            if not n:
                break

        # Strip const qualifier
        name = self._const_re.sub('', name)

        # Strip template parameters from name by recursively removing paired angles
        while True:
            name, n = self._angles_re.subn('', name)
            if not n:
                break

        return name

    # TODO: write utility functions

    def __repr__(self):
        return self.name


class Cycle(Object):
    """A cycle made from recursive function calls."""

    def __init__(self):
        Object.__init__(self)
        # XXX: Do cycles need an id?
        self.functions = set()

    def add_function(self, function):
        assert function not in self.functions
        self.functions.add(function)
        # XXX: Aggregate events?
        if function.cycle is not None:
            for other in function.cycle.functions:
                if function not in self.functions:
                    self.add_function(other)
        function.cycle = self


class Profile(Object):
    """The whole profile."""

    def __init__(self):
        Object.__init__(self)
        self.functions = {}
        self.cycles = []

    def add_function(self, function):
        if function.id in self.functions:
            sys.stderr.write('warning: overwriting function %s (id %s)\n' % (function.name, str(function.id)))
        self.functions[function.id] = function

    def add_cycle(self, cycle):
        self.cycles.append(cycle)

    def validate(self):
        """Validate the edges."""

        for function in compat_itervalues(self.functions):
            for callee_id in compat_keys(function.calls):
                assert function.calls[callee_id].callee_id == callee_id
                if callee_id not in self.functions:
                    sys.stderr.write('warning: call to undefined function %s from function %s\n' % (str(callee_id), function.name))
                    del function.calls[callee_id]

    def find_cycles(self):
        """Find cycles using Tarjan's strongly connected components algorithm."""

        # Apply the Tarjan's algorithm successively until all functions are visited
        visited = set()
        for function in compat_itervalues(self.functions):
            if function not in visited:
                self._tarjan(function, 0, [], {}, {}, visited)
        cycles = []
        for function in compat_itervalues(self.functions):
            if function.cycle is not None and function.cycle not in cycles:
                cycles.append(function.cycle)
        self.cycles = cycles
        if 0:
            for cycle in cycles:
                sys.stderr.write("Cycle:\n")
                for member in cycle.functions:
                    sys.stderr.write("\tFunction %s\n" % member.name)

    def prune_root(self, root):
        visited = set()
        frontier = set([root])
        while len(frontier) > 0:
            node = frontier.pop()
            visited.add(node)
            f = self.functions[node]
            newNodes = f.calls.keys()
            frontier = frontier.union(set(newNodes) - visited)
        subtreeFunctions = {}
        for n in visited:
            subtreeFunctions[n] = self.functions[n]
        self.functions = subtreeFunctions

    def prune_leaf(self, leaf):
        edgesUp = collections.defaultdict(set)
        for f in self.functions.keys():
            for n in self.functions[f].calls.keys():
                edgesUp[n].add(f)
        # build the tree up
        visited = set()
        frontier = set([leaf])
        while len(frontier) > 0:
            node = frontier.pop()
            visited.add(node)
            frontier = frontier.union(edgesUp[node] - visited)
        downTree = set(self.functions.keys())
        upTree = visited
        path = downTree.intersection(upTree)
        pathFunctions = {}
        for n in path:
            f = self.functions[n]
            newCalls = {}
            for c in f.calls.keys():
                if c in path:
                    newCalls[c] = f.calls[c]
            f.calls = newCalls
            pathFunctions[n] = f
        self.functions = pathFunctions


    def getFunctionId(self, funcName):
        for f in self.functions:
            if self.functions[f].name == funcName:
                return f
        return False
    
    def _tarjan(self, function, order, stack, orders, lowlinks, visited):
        """Tarjan's strongly connected components algorithm.

        See also:
        - http://en.wikipedia.org/wiki/Tarjan's_strongly_connected_components_algorithm
        """

        visited.add(function)
        orders[function] = order
        lowlinks[function] = order
        order += 1
        pos = len(stack)
        stack.append(function)
        for call in compat_itervalues(function.calls):
            callee = self.functions[call.callee_id]
            # TODO: use a set to optimize lookup
            if callee not in orders:
                order = self._tarjan(callee, order, stack, orders, lowlinks, visited)
                lowlinks[function] = min(lowlinks[function], lowlinks[callee])
            elif callee in stack:
                lowlinks[function] = min(lowlinks[function], orders[callee])
        if lowlinks[function] == orders[function]:
            # Strongly connected component found
            members = stack[pos:]
            del stack[pos:]
            if len(members) > 1:
                cycle = Cycle()
                for member in members:
                    cycle.add_function(member)
        return order

    def call_ratios(self, event):
        # Aggregate for incoming calls
        cycle_totals = {}
        for cycle in self.cycles:
            cycle_totals[cycle] = 0.0
        function_totals = {}
        for function in compat_itervalues(self.functions):
            function_totals[function] = 0.0

        # Pass 1:  function_total gets the sum of call[event] for all
        #          incoming arrows.  Same for cycle_total for all arrows
        #          that are coming into the *cycle* but are not part of it.
        for function in compat_itervalues(self.functions):
            for call in compat_itervalues(function.calls):
                if call.callee_id != function.id:
                    callee = self.functions[call.callee_id]
                    if event in call.events:
                        function_totals[callee] += call[event]
                        if callee.cycle is not None and callee.cycle is not function.cycle:
                            cycle_totals[callee.cycle] += call[event]
                    else:
                        sys.stderr.write("call_ratios: No data for " + function.name + " call to " + callee.name + "\n")

        # Pass 2:  Compute the ratios.  Each call[event] is scaled by the
        #          function_total of the callee.  Calls into cycles use the
        #          cycle_total, but not calls within cycles.
        for function in compat_itervalues(self.functions):
            for call in compat_itervalues(function.calls):
                assert call.ratio is None
                if call.callee_id != function.id:
                    callee = self.functions[call.callee_id]
                    if event in call.events:
                        if callee.cycle is not None and callee.cycle is not function.cycle:
                            total = cycle_totals[callee.cycle]
                        else:
                            total = function_totals[callee]
                        call.ratio = ratio(call[event], total)
                    else:
                        # Warnings here would only repeat those issued above.
                        call.ratio = 0.0

    def integrate(self, outevent, inevent):
        """Propagate function time ratio along the function calls.

        Must be called after finding the cycles.

        See also:
        - http://citeseer.ist.psu.edu/graham82gprof.html
        """

        # Sanity checking
        assert outevent not in self
        for function in compat_itervalues(self.functions):
            assert outevent not in function
            assert inevent in function
            for call in compat_itervalues(function.calls):
                assert outevent not in call
                if call.callee_id != function.id:
                    assert call.ratio is not None

        # Aggregate the input for each cycle 
        for cycle in self.cycles:
            total = inevent.null()
            for function in compat_itervalues(self.functions):
                total = inevent.aggregate(total, function[inevent])
            self[inevent] = total

        # Integrate along the edges
        total = inevent.null()
        for function in compat_itervalues(self.functions):
            total = inevent.aggregate(total, function[inevent])
            self._integrate_function(function, outevent, inevent)
        self[outevent] = total

    def _integrate_function(self, function, outevent, inevent):
        if function.cycle is not None:
            return self._integrate_cycle(function.cycle, outevent, inevent)
        else:
            if outevent not in function:
                total = function[inevent]
                for call in compat_itervalues(function.calls):
                    if call.callee_id != function.id:
                        total += self._integrate_call(call, outevent, inevent)
                function[outevent] = total
            return function[outevent]
    
    def _integrate_call(self, call, outevent, inevent):
        assert outevent not in call
        assert call.ratio is not None
        callee = self.functions[call.callee_id]
        subtotal = call.ratio *self._integrate_function(callee, outevent, inevent)
        call[outevent] = subtotal
        return subtotal

    def _integrate_cycle(self, cycle, outevent, inevent):
        if outevent not in cycle:

            # Compute the outevent for the whole cycle
            total = inevent.null()
            for member in cycle.functions:
                subtotal = member[inevent]
                for call in compat_itervalues(member.calls):
                    callee = self.functions[call.callee_id]
                    if callee.cycle is not cycle:
                        subtotal += self._integrate_call(call, outevent, inevent)
                total += subtotal
            cycle[outevent] = total
            
            # Compute the time propagated to callers of this cycle
            callees = {}
            for function in compat_itervalues(self.functions):
                if function.cycle is not cycle:
                    for call in compat_itervalues(function.calls):
                        callee = self.functions[call.callee_id]
                        if callee.cycle is cycle:
                            try:
                                callees[callee] += call.ratio
                            except KeyError:
                                callees[callee] = call.ratio
            
            for member in cycle.functions:
                member[outevent] = outevent.null()

            for callee, call_ratio in compat_iteritems(callees):
                ranks = {}
                call_ratios = {}
                partials = {}
                self._rank_cycle_function(cycle, callee, 0, ranks)
                self._call_ratios_cycle(cycle, callee, ranks, call_ratios, set())
                partial = self._integrate_cycle_function(cycle, callee, call_ratio, partials, ranks, call_ratios, outevent, inevent)
                assert partial == max(partials.values())
                assert not total or abs(1.0 - partial/(call_ratio*total)) <= 0.001

        return cycle[outevent]

    def _rank_cycle_function(self, cycle, function, rank, ranks):
        if function not in ranks or ranks[function] > rank:
            ranks[function] = rank
            for call in compat_itervalues(function.calls):
                if call.callee_id != function.id:
                    callee = self.functions[call.callee_id]
                    if callee.cycle is cycle:
                        self._rank_cycle_function(cycle, callee, rank + 1, ranks)

    def _call_ratios_cycle(self, cycle, function, ranks, call_ratios, visited):
        if function not in visited:
            visited.add(function)
            for call in compat_itervalues(function.calls):
                if call.callee_id != function.id:
                    callee = self.functions[call.callee_id]
                    if callee.cycle is cycle:
                        if ranks[callee] > ranks[function]:
                            call_ratios[callee] = call_ratios.get(callee, 0.0) + call.ratio
                            self._call_ratios_cycle(cycle, callee, ranks, call_ratios, visited)

    def _integrate_cycle_function(self, cycle, function, partial_ratio, partials, ranks, call_ratios, outevent, inevent):
        if function not in partials:
            partial = partial_ratio*function[inevent]
            for call in compat_itervalues(function.calls):
                if call.callee_id != function.id:
                    callee = self.functions[call.callee_id]
                    if callee.cycle is not cycle:
                        assert outevent in call
                        partial += partial_ratio*call[outevent]
                    else:
                        if ranks[callee] > ranks[function]:
                            callee_partial = self._integrate_cycle_function(cycle, callee, partial_ratio, partials, ranks, call_ratios, outevent, inevent)
                            call_ratio = ratio(call.ratio, call_ratios[callee])
                            call_partial = call_ratio*callee_partial
                            try:
                                call[outevent] += call_partial
                            except UndefinedEvent:
                                call[outevent] = call_partial
                            partial += call_partial
            partials[function] = partial
            try:
                function[outevent] += partial
            except UndefinedEvent:
                function[outevent] = partial
        return partials[function]

    def aggregate(self, event):
        """Aggregate an event for the whole profile."""

        total = event.null()
        for function in compat_itervalues(self.functions):
            try:
                total = event.aggregate(total, function[event])
            except UndefinedEvent:
                return
        self[event] = total

    def ratio(self, outevent, inevent):
        assert outevent not in self
        assert inevent in self
        for function in compat_itervalues(self.functions):
            assert outevent not in function
            assert inevent in function
            function[outevent] = ratio(function[inevent], self[inevent])
            for call in compat_itervalues(function.calls):
                assert outevent not in call
                if inevent in call:
                    call[outevent] = ratio(call[inevent], self[inevent])
        self[outevent] = 1.0

    def prune(self, node_thres, edge_thres):
        """Prune the profile"""

        # compute the prune ratios
        for function in compat_itervalues(self.functions):
            try:
                function.weight = function[TOTAL_TIME_RATIO]
            except UndefinedEvent:
                pass

            for call in compat_itervalues(function.calls):
                callee = self.functions[call.callee_id]

                if TOTAL_TIME_RATIO in call:
                    # handle exact cases first
                    call.weight = call[TOTAL_TIME_RATIO] 
                else:
                    try:
                        # make a safe estimate
                        call.weight = min(function[TOTAL_TIME_RATIO], callee[TOTAL_TIME_RATIO]) 
                    except UndefinedEvent:
                        pass

        # prune the nodes
        for function_id in compat_keys(self.functions):
            function = self.functions[function_id]
            if function.weight is not None:
                if function.weight < node_thres:
                    del self.functions[function_id]

        # prune the egdes
        for function in compat_itervalues(self.functions):
            for callee_id in compat_keys(function.calls):
                call = function.calls[callee_id]
                if callee_id not in self.functions or call.weight is not None and call.weight < edge_thres:
                    del function.calls[callee_id]
    
    def dump(self):
        for function in compat_itervalues(self.functions):
            sys.stderr.write('Function %s:\n' % (function.name,))
            self._dump_events(function.events)
            for call in compat_itervalues(function.calls):
                callee = self.functions[call.callee_id]
                sys.stderr.write('  Call %s:\n' % (callee.name,))
                self._dump_events(call.events)
        for cycle in self.cycles:
            sys.stderr.write('Cycle:\n')
            self._dump_events(cycle.events)
            for function in cycle.functions:
                sys.stderr.write('  Function %s\n' % (function.name,))

    def _dump_events(self, events):
        for event, value in compat_iteritems(events):
            sys.stderr.write('    %s: %s\n' % (event.name, event.format(value)))


class Struct:
    """Masquerade a dictionary with a structure-like behavior."""

    def __init__(self, attrs = None):
        if attrs is None:
            attrs = {}
        self.__dict__['_attrs'] = attrs
    
    def __getattr__(self, name):
        try:
            return self._attrs[name]
        except KeyError:
            raise AttributeError(name)

    def __setattr__(self, name, value):
        self._attrs[name] = value

    def __str__(self):
        return str(self._attrs)

    def __repr__(self):
        return repr(self._attrs)
    

class ParseError(Exception):
    """Raised when parsing to signal mismatches."""

    def __init__(self, msg, line):
        self.msg = msg
        # TODO: store more source line information
        self.line = line

    def __str__(self):
        return '%s: %r' % (self.msg, self.line)


class Parser:
    """Parser interface."""

    stdinInput = True
    multipleInput = False

    def __init__(self):
        pass

    def parse(self):
        raise NotImplementedError

    
class LineParser(Parser):
    """Base class for parsers that read line-based formats."""

    def __init__(self, stream):
        Parser.__init__(self)
        self._stream = stream
        self.__line = None
        self.__eof = False
        self.line_no = 0

    def readline(self):
        line = self._stream.readline()
        if not line:
            self.__line = ''
            self.__eof = True
        else:
            self.line_no += 1
        line = line.rstrip('\r\n')
        if not PYTHON_3:
            encoding = self._stream.encoding
            if encoding is None:
                encoding = locale.getpreferredencoding()
            line = line.decode(encoding)
        self.__line = line

    def lookahead(self):
        assert self.__line is not None
        return self.__line

    def consume(self):
        assert self.__line is not None
        line = self.__line
        self.readline()
        return line

    def eof(self):
        assert self.__line is not None
        return self.__eof


XML_ELEMENT_START, XML_ELEMENT_END, XML_CHARACTER_DATA, XML_EOF = range(4)


class XmlToken:

    def __init__(self, type, name_or_data, attrs = None, line = None, column = None):
        assert type in (XML_ELEMENT_START, XML_ELEMENT_END, XML_CHARACTER_DATA, XML_EOF)
        self.type = type
        self.name_or_data = name_or_data
        self.attrs = attrs
        self.line = line
        self.column = column

    def __str__(self):
        if self.type == XML_ELEMENT_START:
            return '<' + self.name_or_data + ' ...>'
        if self.type == XML_ELEMENT_END:
            return '</' + self.name_or_data + '>'
        if self.type == XML_CHARACTER_DATA:
            return self.name_or_data
        if self.type == XML_EOF:
            return 'end of file'
        assert 0


class XmlTokenizer:
    """Expat based XML tokenizer."""

    def __init__(self, fp, skip_ws = True):
        self.fp = fp
        self.tokens = []
        self.index = 0
        self.final = False
        self.skip_ws = skip_ws
        
        self.character_pos = 0, 0
        self.character_data = ''
        
        self.parser = xml.parsers.expat.ParserCreate()
        self.parser.StartElementHandler  = self.handle_element_start
        self.parser.EndElementHandler    = self.handle_element_end
        self.parser.CharacterDataHandler = self.handle_character_data
    
    def handle_element_start(self, name, attributes):
        self.finish_character_data()
        line, column = self.pos()
        token = XmlToken(XML_ELEMENT_START, name, attributes, line, column)
        self.tokens.append(token)
    
    def handle_element_end(self, name):
        self.finish_character_data()
        line, column = self.pos()
        token = XmlToken(XML_ELEMENT_END, name, None, line, column)
        self.tokens.append(token)

    def handle_character_data(self, data):
        if not self.character_data:
            self.character_pos = self.pos()
        self.character_data += data
    
    def finish_character_data(self):
        if self.character_data:
            if not self.skip_ws or not self.character_data.isspace(): 
                line, column = self.character_pos
                token = XmlToken(XML_CHARACTER_DATA, self.character_data, None, line, column)
                self.tokens.append(token)
            self.character_data = ''
    
    def next(self):
        size = 16*1024
        while self.index >= len(self.tokens) and not self.final:
            self.tokens = []
            self.index = 0
            data = self.fp.read(size)
            self.final = len(data) < size
            try:
                self.parser.Parse(data, self.final)
            except xml.parsers.expat.ExpatError as e:
                #if e.code == xml.parsers.expat.errors.XML_ERROR_NO_ELEMENTS:
                if e.code == 3:
                    pass
                else:
                    raise e
        if self.index >= len(self.tokens):
            line, column = self.pos()
            token = XmlToken(XML_EOF, None, None, line, column)
        else:
            token = self.tokens[self.index]
            self.index += 1
        return token

    def pos(self):
        return self.parser.CurrentLineNumber, self.parser.CurrentColumnNumber


class XmlTokenMismatch(Exception):

    def __init__(self, expected, found):
        self.expected = expected
        self.found = found

    def __str__(self):
        return '%u:%u: %s expected, %s found' % (self.found.line, self.found.column, str(self.expected), str(self.found))


class XmlParser(Parser):
    """Base XML document parser."""

    def __init__(self, fp):
        Parser.__init__(self)
        self.tokenizer = XmlTokenizer(fp)
        self.consume()
    
    def consume(self):
        self.token = self.tokenizer.next()

    def match_element_start(self, name):
        return self.token.type == XML_ELEMENT_START and self.token.name_or_data == name
    
    def match_element_end(self, name):
        return self.token.type == XML_ELEMENT_END and self.token.name_or_data == name

    def element_start(self, name):
        while self.token.type == XML_CHARACTER_DATA:
            self.consume()
        if self.token.type != XML_ELEMENT_START:
            raise XmlTokenMismatch(XmlToken(XML_ELEMENT_START, name), self.token)
        if self.token.name_or_data != name:
            raise XmlTokenMismatch(XmlToken(XML_ELEMENT_START, name), self.token)
        attrs = self.token.attrs
        self.consume()
        return attrs
    
    def element_end(self, name):
        while self.token.type == XML_CHARACTER_DATA:
            self.consume()
        if self.token.type != XML_ELEMENT_END:
            raise XmlTokenMismatch(XmlToken(XML_ELEMENT_END, name), self.token)
        if self.token.name_or_data != name:
            raise XmlTokenMismatch(XmlToken(XML_ELEMENT_END, name), self.token)
        self.consume()

    def character_data(self, strip = True):
        data = ''
        while self.token.type == XML_CHARACTER_DATA:
            data += self.token.name_or_data
            self.consume()
        if strip:
            data = data.strip()
        return data


class GprofParser(Parser):
    """Parser for GNU gprof output.

    See also:
    - Chapter "Interpreting gprof's Output" from the GNU gprof manual
      http://sourceware.org/binutils/docs-2.18/gprof/Call-Graph.html#Call-Graph
    - File "cg_print.c" from the GNU gprof source code
      http://sourceware.org/cgi-bin/cvsweb.cgi/~checkout~/src/gprof/cg_print.c?rev=1.12&cvsroot=src
    """

    def __init__(self, fp):
        Parser.__init__(self)
        self.fp = fp
        self.functions = {}
        self.cycles = {}

    def readline(self):
        line = self.fp.readline()
        if not line:
            sys.stderr.write('error: unexpected end of file\n')
            sys.exit(1)
        line = line.rstrip('\r\n')
        return line

    _int_re = re.compile(r'^\d+$')
    _float_re = re.compile(r'^\d+\.\d+$')

    def translate(self, mo):
        """Extract a structure from a match object, while translating the types in the process."""
        attrs = {}
        groupdict = mo.groupdict()
        for name, value in compat_iteritems(groupdict):
            if value is None:
                value = None
            elif self._int_re.match(value):
                value = int(value)
            elif self._float_re.match(value):
                value = float(value)
            attrs[name] = (value)
        return Struct(attrs)

    _cg_header_re = re.compile(
        # original gprof header
        r'^\s+called/total\s+parents\s*$|' +
        r'^index\s+%time\s+self\s+descendents\s+called\+self\s+name\s+index\s*$|' +
        r'^\s+called/total\s+children\s*$|' +
        # GNU gprof header
        r'^index\s+%\s+time\s+self\s+children\s+called\s+name\s*$'
    )

    _cg_ignore_re = re.compile(
        # spontaneous
        r'^\s+<spontaneous>\s*$|'
        # internal calls (such as "mcount")
        r'^.*\((\d+)\)$'
    )

    _cg_primary_re = re.compile(
        r'^\[(?P<index>\d+)\]?' + 
        r'\s+(?P<percentage_time>\d+\.\d+)' + 
        r'\s+(?P<self>\d+\.\d+)' + 
        r'\s+(?P<descendants>\d+\.\d+)' + 
        r'\s+(?:(?P<called>\d+)(?:\+(?P<called_self>\d+))?)?' + 
        r'\s+(?P<name>\S.*?)' +
        r'(?:\s+<cycle\s(?P<cycle>\d+)>)?' +
        r'\s\[(\d+)\]$'
    )

    _cg_parent_re = re.compile(
        r'^\s+(?P<self>\d+\.\d+)?' + 
        r'\s+(?P<descendants>\d+\.\d+)?' + 
        r'\s+(?P<called>\d+)(?:/(?P<called_total>\d+))?' + 
        r'\s+(?P<name>\S.*?)' +
        r'(?:\s+<cycle\s(?P<cycle>\d+)>)?' +
        r'\s\[(?P<index>\d+)\]$'
    )

    _cg_child_re = _cg_parent_re

    _cg_cycle_header_re = re.compile(
        r'^\[(?P<index>\d+)\]?' + 
        r'\s+(?P<percentage_time>\d+\.\d+)' + 
        r'\s+(?P<self>\d+\.\d+)' + 
        r'\s+(?P<descendants>\d+\.\d+)' + 
        r'\s+(?:(?P<called>\d+)(?:\+(?P<called_self>\d+))?)?' + 
        r'\s+<cycle\s(?P<cycle>\d+)\sas\sa\swhole>' +
        r'\s\[(\d+)\]$'
    )

    _cg_cycle_member_re = re.compile(
        r'^\s+(?P<self>\d+\.\d+)?' + 
        r'\s+(?P<descendants>\d+\.\d+)?' + 
        r'\s+(?P<called>\d+)(?:\+(?P<called_self>\d+))?' + 
        r'\s+(?P<name>\S.*?)' +
        r'(?:\s+<cycle\s(?P<cycle>\d+)>)?' +
        r'\s\[(?P<index>\d+)\]$'
    )

    _cg_sep_re = re.compile(r'^--+$')

    def parse_function_entry(self, lines):
        parents = []
        children = []

        while True:
            if not lines:
                sys.stderr.write('warning: unexpected end of entry\n')
            line = lines.pop(0)
            if line.startswith('['):
                break
        
            # read function parent line
            mo = self._cg_parent_re.match(line)
            if not mo:
                if self._cg_ignore_re.match(line):
                    continue
                sys.stderr.write('warning: unrecognized call graph entry: %r\n' % line)
            else:
                parent = self.translate(mo)
                parents.append(parent)

        # read primary line
        mo = self._cg_primary_re.match(line)
        if not mo:
            sys.stderr.write('warning: unrecognized call graph entry: %r\n' % line)
            return
        else:
            function = self.translate(mo)

        while lines:
            line = lines.pop(0)
            
            # read function subroutine line
            mo = self._cg_child_re.match(line)
            if not mo:
                if self._cg_ignore_re.match(line):
                    continue
                sys.stderr.write('warning: unrecognized call graph entry: %r\n' % line)
            else:
                child = self.translate(mo)
                children.append(child)
        
        function.parents = parents
        function.children = children

        self.functions[function.index] = function

    def parse_cycle_entry(self, lines):

        # read cycle header line
        line = lines[0]
        mo = self._cg_cycle_header_re.match(line)
        if not mo:
            sys.stderr.write('warning: unrecognized call graph entry: %r\n' % line)
            return
        cycle = self.translate(mo)

        # read cycle member lines
        cycle.functions = []
        for line in lines[1:]:
            mo = self._cg_cycle_member_re.match(line)
            if not mo:
                sys.stderr.write('warning: unrecognized call graph entry: %r\n' % line)
                continue
            call = self.translate(mo)
            cycle.functions.append(call)
        
        self.cycles[cycle.cycle] = cycle

    def parse_cg_entry(self, lines):
        if lines[0].startswith("["):
            self.parse_cycle_entry(lines)
        else:
            self.parse_function_entry(lines)

    def parse_cg(self):
        """Parse the call graph."""

        # skip call graph header
        while not self._cg_header_re.match(self.readline()):
            pass
        line = self.readline()
        while self._cg_header_re.match(line):
            line = self.readline()

        # process call graph entries
        entry_lines = []
        while line != '\014': # form feed
            if line and not line.isspace():
                if self._cg_sep_re.match(line):
                    self.parse_cg_entry(entry_lines)
                    entry_lines = []
                else:
                    entry_lines.append(line)            
            line = self.readline()
    
    def parse(self):
        self.parse_cg()
        self.fp.close()

        profile = Profile()
        profile[TIME] = 0.0
        
        cycles = {}
        for index in self.cycles:
            cycles[index] = Cycle()

        for entry in compat_itervalues(self.functions):
            # populate the function
            function = Function(entry.index, entry.name)
            function[TIME] = entry.self
            if entry.called is not None:
                function.called = entry.called
            if entry.called_self is not None:
                call = Call(entry.index)
                call[CALLS] = entry.called_self
                function.called += entry.called_self
            
            # populate the function calls
            for child in entry.children:
                call = Call(child.index)
                
                assert child.called is not None
                call[CALLS] = child.called

                if child.index not in self.functions:
                    # NOTE: functions that were never called but were discovered by gprof's 
                    # static call graph analysis dont have a call graph entry so we need
                    # to add them here
                    missing = Function(child.index, child.name)
                    function[TIME] = 0.0
                    function.called = 0
                    profile.add_function(missing)

                function.add_call(call)

            profile.add_function(function)

            if entry.cycle is not None:
                try:
                    cycle = cycles[entry.cycle]
                except KeyError:
                    sys.stderr.write('warning: <cycle %u as a whole> entry missing\n' % entry.cycle) 
                    cycle = Cycle()
                    cycles[entry.cycle] = cycle
                cycle.add_function(function)

            profile[TIME] = profile[TIME] + function[TIME]

        for cycle in compat_itervalues(cycles):
            profile.add_cycle(cycle)

        # Compute derived events
        profile.validate()
        profile.ratio(TIME_RATIO, TIME)
        profile.call_ratios(CALLS)
        profile.integrate(TOTAL_TIME, TIME)
        profile.ratio(TOTAL_TIME_RATIO, TOTAL_TIME)

        return profile


# Clone&hack of GprofParser for VTune Amplifier XE 2013 gprof-cc output.
# Tested only with AXE 2013 for Windows.
#   - Use total times as reported by AXE.
#   - In the absence of call counts, call ratios are faked from the relative
#     proportions of total time.  This affects only the weighting of the calls.
#   - Different header, separator, and end marker.
#   - Extra whitespace after function names.
#   - You get a full entry for <spontaneous>, which does not have parents.
#   - Cycles do have parents.  These are saved but unused (as they are
#     for functions).
#   - Disambiguated "unrecognized call graph entry" error messages.
# Notes:
#   - Total time of functions as reported by AXE passes the val3 test.
#   - CPU Time:Children in the input is sometimes a negative number.  This
#     value goes to the variable descendants, which is unused.
#   - The format of gprof-cc reports is unaffected by the use of
#       -knob enable-call-counts=true (no call counts, ever), or
#       -show-as=samples (results are quoted in seconds regardless).
class AXEParser(Parser):
    "Parser for VTune Amplifier XE 2013 gprof-cc report output."

    def __init__(self, fp):
        Parser.__init__(self)
        self.fp = fp
        self.functions = {}
        self.cycles = {}

    def readline(self):
        line = self.fp.readline()
        if not line:
            sys.stderr.write('error: unexpected end of file\n')
            sys.exit(1)
        line = line.rstrip('\r\n')
        return line

    _int_re = re.compile(r'^\d+$')
    _float_re = re.compile(r'^\d+\.\d+$')

    def translate(self, mo):
        """Extract a structure from a match object, while translating the types in the process."""
        attrs = {}
        groupdict = mo.groupdict()
        for name, value in compat_iteritems(groupdict):
            if value is None:
                value = None
            elif self._int_re.match(value):
                value = int(value)
            elif self._float_re.match(value):
                value = float(value)
            attrs[name] = (value)
        return Struct(attrs)

    _cg_header_re = re.compile(
        '^Index |'
        '^-----+ '
    )

    _cg_footer_re = re.compile('^Index\s+Function\s*$')

    _cg_primary_re = re.compile(
        r'^\[(?P<index>\d+)\]?' + 
        r'\s+(?P<percentage_time>\d+\.\d+)' + 
        r'\s+(?P<self>\d+\.\d+)' + 
        r'\s+(?P<descendants>\d+\.\d+)' + 
        r'\s+(?P<name>\S.*?)' +
        r'(?:\s+<cycle\s(?P<cycle>\d+)>)?' +
        r'\s+\[(\d+)\]$'
    )

    _cg_parent_re = re.compile(
        r'^\s+(?P<self>\d+\.\d+)?' + 
        r'\s+(?P<descendants>\d+\.\d+)?' + 
        r'\s+(?P<name>\S.*?)' +
        r'(?:\s+<cycle\s(?P<cycle>\d+)>)?' +
        r'\s+\[(?P<index>\d+)\]$'
    )

    _cg_child_re = _cg_parent_re

    _cg_cycle_header_re = re.compile(
        r'^\[(?P<index>\d+)\]?' + 
        r'\s+(?P<percentage_time>\d+\.\d+)' + 
        r'\s+(?P<self>\d+\.\d+)' + 
        r'\s+(?P<descendants>\d+\.\d+)' + 
        r'\s+<cycle\s(?P<cycle>\d+)\sas\sa\swhole>' +
        r'\s+\[(\d+)\]$'
    )

    _cg_cycle_member_re = re.compile(
        r'^\s+(?P<self>\d+\.\d+)?' + 
        r'\s+(?P<descendants>\d+\.\d+)?' + 
        r'\s+(?P<name>\S.*?)' +
        r'(?:\s+<cycle\s(?P<cycle>\d+)>)?' +
        r'\s+\[(?P<index>\d+)\]$'
    )

    def parse_function_entry(self, lines):
        parents = []
        children = []

        while True:
            if not lines:
                sys.stderr.write('warning: unexpected end of entry\n')
                return
            line = lines.pop(0)
            if line.startswith('['):
                break
        
            # read function parent line
            mo = self._cg_parent_re.match(line)
            if not mo:
                sys.stderr.write('warning: unrecognized call graph entry (1): %r\n' % line)
            else:
                parent = self.translate(mo)
                if parent.name != '<spontaneous>':
                    parents.append(parent)

        # read primary line
        mo = self._cg_primary_re.match(line)
        if not mo:
            sys.stderr.write('warning: unrecognized call graph entry (2): %r\n' % line)
            return
        else:
            function = self.translate(mo)

        while lines:
            line = lines.pop(0)
            
            # read function subroutine line
            mo = self._cg_child_re.match(line)
            if not mo:
                sys.stderr.write('warning: unrecognized call graph entry (3): %r\n' % line)
            else:
                child = self.translate(mo)
                if child.name != '<spontaneous>':
                    children.append(child)

        if function.name != '<spontaneous>':
            function.parents = parents
            function.children = children

            self.functions[function.index] = function

    def parse_cycle_entry(self, lines):

        # Process the parents that were not there in gprof format.
        parents = []
        while True:
            if not lines:
                sys.stderr.write('warning: unexpected end of cycle entry\n')
                return
            line = lines.pop(0)
            if line.startswith('['):
                break
            mo = self._cg_parent_re.match(line)
            if not mo:
                sys.stderr.write('warning: unrecognized call graph entry (6): %r\n' % line)
            else:
                parent = self.translate(mo)
                if parent.name != '<spontaneous>':
                    parents.append(parent)

        # read cycle header line
        mo = self._cg_cycle_header_re.match(line)
        if not mo:
            sys.stderr.write('warning: unrecognized call graph entry (4): %r\n' % line)
            return
        cycle = self.translate(mo)

        # read cycle member lines
        cycle.functions = []
        for line in lines[1:]:
            mo = self._cg_cycle_member_re.match(line)
            if not mo:
                sys.stderr.write('warning: unrecognized call graph entry (5): %r\n' % line)
                continue
            call = self.translate(mo)
            cycle.functions.append(call)
        
        cycle.parents = parents
        self.cycles[cycle.cycle] = cycle

    def parse_cg_entry(self, lines):
        if any("as a whole" in linelooper for linelooper in lines):
            self.parse_cycle_entry(lines)
        else:
            self.parse_function_entry(lines)

    def parse_cg(self):
        """Parse the call graph."""

        # skip call graph header
        line = self.readline()
        while self._cg_header_re.match(line):
            line = self.readline()

        # process call graph entries
        entry_lines = []
        # An EOF in readline terminates the program without returning.
        while not self._cg_footer_re.match(line):
            if line.isspace():
                self.parse_cg_entry(entry_lines)
                entry_lines = []
            else:
                entry_lines.append(line)            
            line = self.readline()

    def parse(self):
        sys.stderr.write('warning: for axe format, edge weights are unreliable estimates derived from\nfunction total times.\n')
        self.parse_cg()
        self.fp.close()

        profile = Profile()
        profile[TIME] = 0.0
        
        cycles = {}
        for index in self.cycles:
            cycles[index] = Cycle()

        for entry in compat_itervalues(self.functions):
            # populate the function
            function = Function(entry.index, entry.name)
            function[TIME] = entry.self
            function[TOTAL_TIME_RATIO] = entry.percentage_time / 100.0
            
            # populate the function calls
            for child in entry.children:
                call = Call(child.index)
                # The following bogus value affects only the weighting of
                # the calls.
                call[TOTAL_TIME_RATIO] = function[TOTAL_TIME_RATIO]

                if child.index not in self.functions:
                    # NOTE: functions that were never called but were discovered by gprof's 
                    # static call graph analysis dont have a call graph entry so we need
                    # to add them here
                    # FIXME: Is this applicable?
                    missing = Function(child.index, child.name)
                    function[TIME] = 0.0
                    profile.add_function(missing)

                function.add_call(call)

            profile.add_function(function)

            if entry.cycle is not None:
                try:
                    cycle = cycles[entry.cycle]
                except KeyError:
                    sys.stderr.write('warning: <cycle %u as a whole> entry missing\n' % entry.cycle) 
                    cycle = Cycle()
                    cycles[entry.cycle] = cycle
                cycle.add_function(function)

            profile[TIME] = profile[TIME] + function[TIME]

        for cycle in compat_itervalues(cycles):
            profile.add_cycle(cycle)

        # Compute derived events.
        profile.validate()
        profile.ratio(TIME_RATIO, TIME)
        # Lacking call counts, fake call ratios based on total times.
        profile.call_ratios(TOTAL_TIME_RATIO)
        # The TOTAL_TIME_RATIO of functions is already set.  Propagate that
        # total time to the calls.  (TOTAL_TIME is neither set nor used.)
        for function in compat_itervalues(profile.functions):
            for call in compat_itervalues(function.calls):
                if call.ratio is not None:
                    callee = profile.functions[call.callee_id]
                    call[TOTAL_TIME_RATIO] = call.ratio * callee[TOTAL_TIME_RATIO];

        return profile


class CallgrindParser(LineParser):
    """Parser for valgrind's callgrind tool.
    
    See also:
    - http://valgrind.org/docs/manual/cl-format.html
    """

    _call_re = re.compile('^calls=\s*(\d+)\s+((\d+|\+\d+|-\d+|\*)\s+)+$')

    def __init__(self, infile):
        LineParser.__init__(self, infile)

        # Textual positions
        self.position_ids = {}
        self.positions = {}

        # Numeric positions
        self.num_positions = 1
        self.cost_positions = ['line']
        self.last_positions = [0]

        # Events
        self.num_events = 0
        self.cost_events = []

        self.profile = Profile()
        self.profile[SAMPLES] = 0

    def parse(self):
        # read lookahead
        self.readline()

        self.parse_key('version')
        self.parse_key('creator')
        while self.parse_part():
            pass
        if not self.eof():
            sys.stderr.write('warning: line %u: unexpected line\n' % self.line_no)
            sys.stderr.write('%s\n' % self.lookahead())

        # compute derived data
        self.profile.validate()
        self.profile.find_cycles()
        self.profile.ratio(TIME_RATIO, SAMPLES)
        self.profile.call_ratios(CALLS)
        self.profile.integrate(TOTAL_TIME_RATIO, TIME_RATIO)

        return self.profile

    def parse_part(self):
        if not self.parse_header_line():
            return False
        while self.parse_header_line():
            pass
        if not self.parse_body_line():
            return False
        while self.parse_body_line():
            pass
        return True

    def parse_header_line(self):
        return \
            self.parse_empty() or \
            self.parse_comment() or \
            self.parse_part_detail() or \
            self.parse_description() or \
            self.parse_event_specification() or \
            self.parse_cost_line_def() or \
            self.parse_cost_summary()

    _detail_keys = set(('cmd', 'pid', 'thread', 'part'))

    def parse_part_detail(self):
        return self.parse_keys(self._detail_keys)

    def parse_description(self):
        return self.parse_key('desc') is not None

    def parse_event_specification(self):
        event = self.parse_key('event')
        if event is None:
            return False
        return True

    def parse_cost_line_def(self):
        pair = self.parse_keys(('events', 'positions'))
        if pair is None:
            return False
        key, value = pair
        items = value.split()
        if key == 'events':
            self.num_events = len(items)
            self.cost_events = items
        if key == 'positions':
            self.num_positions = len(items)
            self.cost_positions = items
            self.last_positions = [0]*self.num_positions
        return True

    def parse_cost_summary(self):
        pair = self.parse_keys(('summary', 'totals'))
        if pair is None:
            return False
        return True

    def parse_body_line(self):
        return \
            self.parse_empty() or \
            self.parse_comment() or \
            self.parse_cost_line() or \
            self.parse_position_spec() or \
            self.parse_association_spec()

    __subpos_re = r'(0x[0-9a-fA-F]+|\d+|\+\d+|-\d+|\*)'
    _cost_re = re.compile(r'^' + 
        __subpos_re + r'( +' + __subpos_re + r')*' +
        r'( +\d+)*' +
    '$')

    def parse_cost_line(self, calls=None):
        line = self.lookahead().rstrip()
        mo = self._cost_re.match(line)
        if not mo:
            return False

        function = self.get_function()

        if calls is None:
            # Unlike other aspects, call object (cob) is relative not to the
            # last call object, but to the caller's object (ob), so try to
            # update it when processing a functions cost line
            try:
                self.positions['cob'] = self.positions['ob']
            except KeyError:
                pass

        values = line.split()
        assert len(values) <= self.num_positions + self.num_events

        positions = values[0 : self.num_positions]
        events = values[self.num_positions : ]
        events += ['0']*(self.num_events - len(events))

        for i in range(self.num_positions):
            position = positions[i]
            if position == '*':
                position = self.last_positions[i]
            elif position[0] in '-+':
                position = self.last_positions[i] + int(position)
            elif position.startswith('0x'):
                position = int(position, 16)
            else:
                position = int(position)
            self.last_positions[i] = position

        events = [float(event) for event in events]

        if calls is None:
            function[SAMPLES] += events[0] 
            self.profile[SAMPLES] += events[0]
        else:
            callee = self.get_callee()
            callee.called += calls
    
            try:
                call = function.calls[callee.id]
            except KeyError:
                call = Call(callee.id)
                call[CALLS] = calls
                call[SAMPLES] = events[0]
                function.add_call(call)
            else:
                call[CALLS] += calls
                call[SAMPLES] += events[0]

        self.consume()
        return True

    def parse_association_spec(self):
        line = self.lookahead()
        if not line.startswith('calls='):
            return False

        _, values = line.split('=', 1)
        values = values.strip().split()
        calls = int(values[0])
        call_position = values[1:]
        self.consume()

        self.parse_cost_line(calls)

        return True

    _position_re = re.compile('^(?P<position>[cj]?(?:ob|fl|fi|fe|fn))=\s*(?:\((?P<id>\d+)\))?(?:\s*(?P<name>.+))?')

    _position_table_map = {
        'ob': 'ob',
        'fl': 'fl',
        'fi': 'fl',
        'fe': 'fl',
        'fn': 'fn',
        'cob': 'ob',
        'cfl': 'fl',
        'cfi': 'fl',
        'cfe': 'fl',
        'cfn': 'fn',
        'jfi': 'fl',
    }

    _position_map = {
        'ob': 'ob',
        'fl': 'fl',
        'fi': 'fl',
        'fe': 'fl',
        'fn': 'fn',
        'cob': 'cob',
        'cfl': 'cfl',
        'cfi': 'cfl',
        'cfe': 'cfl',
        'cfn': 'cfn',
        'jfi': 'jfi',
    }

    def parse_position_spec(self):
        line = self.lookahead()
        
        if line.startswith('jump=') or line.startswith('jcnd='):
            self.consume()
            return True

        mo = self._position_re.match(line)
        if not mo:
            return False

        position, id, name = mo.groups()
        if id:
            table = self._position_table_map[position]
            if name:
                self.position_ids[(table, id)] = name
            else:
                name = self.position_ids.get((table, id), '')
        self.positions[self._position_map[position]] = name

        self.consume()
        return True

    def parse_empty(self):
        if self.eof():
            return False
        line = self.lookahead()
        if line.strip():
            return False
        self.consume()
        return True

    def parse_comment(self):
        line = self.lookahead()
        if not line.startswith('#'):
            return False
        self.consume()
        return True

    _key_re = re.compile(r'^(\w+):')

    def parse_key(self, key):
        pair = self.parse_keys((key,))
        if not pair:
            return None
        key, value = pair
        return value
        line = self.lookahead()
        mo = self._key_re.match(line)
        if not mo:
            return None
        key, value = line.split(':', 1)
        if key not in keys:
            return None
        value = value.strip()
        self.consume()
        return key, value

    def parse_keys(self, keys):
        line = self.lookahead()
        mo = self._key_re.match(line)
        if not mo:
            return None
        key, value = line.split(':', 1)
        if key not in keys:
            return None
        value = value.strip()
        self.consume()
        return key, value

    def make_function(self, module, filename, name):
        # FIXME: module and filename are not being tracked reliably
        #id = '|'.join((module, filename, name))
        id = name
        try:
            function = self.profile.functions[id]
        except KeyError:
            function = Function(id, name)
            if module:
                function.module = os.path.basename(module)
            function[SAMPLES] = 0
            function.called = 0
            self.profile.add_function(function)
        return function

    def get_function(self):
        module = self.positions.get('ob', '')
        filename = self.positions.get('fl', '') 
        function = self.positions.get('fn', '') 
        return self.make_function(module, filename, function)

    def get_callee(self):
        module = self.positions.get('cob', '')
        filename = self.positions.get('cfi', '') 
        function = self.positions.get('cfn', '') 
        return self.make_function(module, filename, function)


class PerfParser(LineParser):
    """Parser for linux perf callgraph output.

    It expects output generated with

        perf record -g
        perf script | gprof2dot.py --format=perf
    """

    def __init__(self, infile):
        LineParser.__init__(self, infile)
        self.profile = Profile()

    def readline(self):
        # Override LineParser.readline to ignore comment lines
        while True:
            LineParser.readline(self)
            if self.eof() or not self.lookahead().startswith('#'):
                break

    def parse(self):
        # read lookahead
        self.readline()

        profile = self.profile
        profile[SAMPLES] = 0
        while not self.eof():
            self.parse_event()

        # compute derived data
        profile.validate()
        profile.find_cycles()
        profile.ratio(TIME_RATIO, SAMPLES)
        profile.call_ratios(SAMPLES2)
        if totalMethod == "callratios":
            # Heuristic approach.  TOTAL_SAMPLES is unused.
            profile.integrate(TOTAL_TIME_RATIO, TIME_RATIO)
        elif totalMethod == "callstacks":
            # Use the actual call chains for functions.
            profile[TOTAL_SAMPLES] = profile[SAMPLES]
            profile.ratio(TOTAL_TIME_RATIO, TOTAL_SAMPLES)
            # Then propagate that total time to the calls.
            for function in compat_itervalues(profile.functions):
                for call in compat_itervalues(function.calls):
                    if call.ratio is not None:
                        callee = profile.functions[call.callee_id]
                        call[TOTAL_TIME_RATIO] = call.ratio * callee[TOTAL_TIME_RATIO];
        else:
            assert False

        return profile

    def parse_event(self):
        if self.eof():
            return

        line = self.consume()
        assert line

        callchain = self.parse_callchain()
        if not callchain:
            return

        callee = callchain[0]
        callee[SAMPLES] += 1
        self.profile[SAMPLES] += 1

        for caller in callchain[1:]:
            try:
                call = caller.calls[callee.id]
            except KeyError:
                call = Call(callee.id)
                call[SAMPLES2] = 1
                caller.add_call(call)
            else:
                call[SAMPLES2] += 1

            callee = caller

        # Increment TOTAL_SAMPLES only once on each function.
        stack = set(callchain)
        for function in stack:
            function[TOTAL_SAMPLES] += 1

    def parse_callchain(self):
        callchain = []
        while self.lookahead():
            function = self.parse_call()
            if function is None:
                break
            callchain.append(function)
        if self.lookahead() == '':
            self.consume()
        return callchain

    call_re = re.compile(r'^\s+(?P<address>[0-9a-fA-F]+)\s+(?P<symbol>.*)\s+\((?P<module>[^)]*)\)$')

    def parse_call(self):
        line = self.consume()
        mo = self.call_re.match(line)
        assert mo
        if not mo:
            return None

        function_name = mo.group('symbol')
        if not function_name:
            function_name = mo.group('address')

        module = mo.group('module')

        function_id = function_name + ':' + module

        try:
            function = self.profile.functions[function_id]
        except KeyError:
            function = Function(function_id, function_name)
            function.module = os.path.basename(module)
            function[SAMPLES] = 0
            function[TOTAL_SAMPLES] = 0
            self.profile.add_function(function)

        return function


class OprofileParser(LineParser):
    """Parser for oprofile callgraph output.
    
    See also:
    - http://oprofile.sourceforge.net/doc/opreport.html#opreport-callgraph
    """

    _fields_re = {
        'samples': r'(\d+)',
        '%': r'(\S+)',
        'linenr info': r'(?P<source>\(no location information\)|\S+:\d+)',
        'image name': r'(?P<image>\S+(?:\s\(tgid:[^)]*\))?)',
        'app name': r'(?P<application>\S+)',
        'symbol name': r'(?P<symbol>\(no symbols\)|.+?)',
    }

    def __init__(self, infile):
        LineParser.__init__(self, infile)
        self.entries = {}
        self.entry_re = None

    def add_entry(self, callers, function, callees):
        try:
            entry = self.entries[function.id]
        except KeyError:
            self.entries[function.id] = (callers, function, callees)
        else:
            callers_total, function_total, callees_total = entry
            self.update_subentries_dict(callers_total, callers)
            function_total.samples += function.samples
            self.update_subentries_dict(callees_total, callees)
    
    def update_subentries_dict(self, totals, partials):
        for partial in compat_itervalues(partials):
            try:
                total = totals[partial.id]
            except KeyError:
                totals[partial.id] = partial
            else:
                total.samples += partial.samples
        
    def parse(self):
        # read lookahead
        self.readline()

        self.parse_header()
        while self.lookahead():
            self.parse_entry()

        profile = Profile()

        reverse_call_samples = {}
        
        # populate the profile
        profile[SAMPLES] = 0
        for _callers, _function, _callees in compat_itervalues(self.entries):
            function = Function(_function.id, _function.name)
            function[SAMPLES] = _function.samples
            profile.add_function(function)
            profile[SAMPLES] += _function.samples

            if _function.application:
                function.process = os.path.basename(_function.application)
            if _function.image:
                function.module = os.path.basename(_function.image)

            total_callee_samples = 0
            for _callee in compat_itervalues(_callees):
                total_callee_samples += _callee.samples

            for _callee in compat_itervalues(_callees):
                if not _callee.self:
                    call = Call(_callee.id)
                    call[SAMPLES2] = _callee.samples
                    function.add_call(call)
                
        # compute derived data
        profile.validate()
        profile.find_cycles()
        profile.ratio(TIME_RATIO, SAMPLES)
        profile.call_ratios(SAMPLES2)
        profile.integrate(TOTAL_TIME_RATIO, TIME_RATIO)

        return profile

    def parse_header(self):
        while not self.match_header():
            self.consume()
        line = self.lookahead()
        fields = re.split(r'\s\s+', line)
        entry_re = r'^\s*' + r'\s+'.join([self._fields_re[field] for field in fields]) + r'(?P<self>\s+\[self\])?$'
        self.entry_re = re.compile(entry_re)
        self.skip_separator()

    def parse_entry(self):
        callers = self.parse_subentries()
        if self.match_primary():
            function = self.parse_subentry()
            if function is not None:
                callees = self.parse_subentries()
                self.add_entry(callers, function, callees)
        self.skip_separator()

    def parse_subentries(self):
        subentries = {}
        while self.match_secondary():
            subentry = self.parse_subentry()
            subentries[subentry.id] = subentry
        return subentries

    def parse_subentry(self):
        entry = Struct()
        line = self.consume()
        mo = self.entry_re.match(line)
        if not mo:
            raise ParseError('failed to parse', line)
        fields = mo.groupdict()
        entry.samples = int(mo.group(1))
        if 'source' in fields and fields['source'] != '(no location information)':
            source = fields['source']
            filename, lineno = source.split(':')
            entry.filename = filename
            entry.lineno = int(lineno)
        else:
            source = ''
            entry.filename = None
            entry.lineno = None
        entry.image = fields.get('image', '')
        entry.application = fields.get('application', '')
        if 'symbol' in fields and fields['symbol'] != '(no symbols)':
            entry.symbol = fields['symbol']
        else:
            entry.symbol = ''
        if entry.symbol.startswith('"') and entry.symbol.endswith('"'):
            entry.symbol = entry.symbol[1:-1]
        entry.id = ':'.join((entry.application, entry.image, source, entry.symbol))
        entry.self = fields.get('self', None) != None
        if entry.self:
            entry.id += ':self'
        if entry.symbol:
            entry.name = entry.symbol
        else:
            entry.name = entry.image
        return entry

    def skip_separator(self):
        while not self.match_separator():
            self.consume()
        self.consume()

    def match_header(self):
        line = self.lookahead()
        return line.startswith('samples')

    def match_separator(self):
        line = self.lookahead()
        return line == '-'*len(line)

    def match_primary(self):
        line = self.lookahead()
        return not line[:1].isspace()
    
    def match_secondary(self):
        line = self.lookahead()
        return line[:1].isspace()


class HProfParser(LineParser):
    """Parser for java hprof output
    
    See also:
    - http://java.sun.com/developer/technicalArticles/Programming/HPROF.html
    """

    trace_re = re.compile(r'\t(.*)\((.*):(.*)\)')
    trace_id_re = re.compile(r'^TRACE (\d+):$')

    def __init__(self, infile):
        LineParser.__init__(self, infile)
        self.traces = {}
        self.samples = {}

    def parse(self):
        # read lookahead
        self.readline()

        while not self.lookahead().startswith('------'): self.consume()
        while not self.lookahead().startswith('TRACE '): self.consume()

        self.parse_traces()

        while not self.lookahead().startswith('CPU'):
            self.consume()

        self.parse_samples()

        # populate the profile
        profile = Profile()
        profile[SAMPLES] = 0

        functions = {}

        # build up callgraph
        for id, trace in compat_iteritems(self.traces):
            if not id in self.samples: continue
            mtime = self.samples[id][0]
            last = None

            for func, file, line in trace:
                if not func in functions:
                    function = Function(func, func)
                    function[SAMPLES] = 0
                    profile.add_function(function)
                    functions[func] = function

                function = functions[func]
                # allocate time to the deepest method in the trace
                if not last:
                    function[SAMPLES] += mtime
                    profile[SAMPLES] += mtime
                else:
                    c = function.get_call(last)
                    c[SAMPLES2] += mtime

                last = func

        # compute derived data
        profile.validate()
        profile.find_cycles()
        profile.ratio(TIME_RATIO, SAMPLES)
        profile.call_ratios(SAMPLES2)
        profile.integrate(TOTAL_TIME_RATIO, TIME_RATIO)

        return profile

    def parse_traces(self):
        while self.lookahead().startswith('TRACE '):
            self.parse_trace()

    def parse_trace(self):
        l = self.consume()
        mo = self.trace_id_re.match(l)
        tid = mo.group(1)
        last = None
        trace = []

        while self.lookahead().startswith('\t'):
            l = self.consume()
            match = self.trace_re.search(l)
            if not match:
                #sys.stderr.write('Invalid line: %s\n' % l)
                break
            else:
                function_name, file, line = match.groups()
                trace += [(function_name, file, line)]

        self.traces[int(tid)] = trace

    def parse_samples(self):
        self.consume()
        self.consume()

        while not self.lookahead().startswith('CPU'):
            rank, percent_self, percent_accum, count, traceid, method = self.lookahead().split()
            self.samples[int(traceid)] = (int(count), method)
            self.consume()


class SysprofParser(XmlParser):

    def __init__(self, stream):
        XmlParser.__init__(self, stream)

    def parse(self):
        objects = {}
        nodes = {}

        self.element_start('profile')
        while self.token.type == XML_ELEMENT_START:
            if self.token.name_or_data == 'objects':
                assert not objects
                objects = self.parse_items('objects')
            elif self.token.name_or_data == 'nodes':
                assert not nodes
                nodes = self.parse_items('nodes')
            else:
                self.parse_value(self.token.name_or_data)
        self.element_end('profile')

        return self.build_profile(objects, nodes)

    def parse_items(self, name):
        assert name[-1] == 's'
        items = {}
        self.element_start(name)
        while self.token.type == XML_ELEMENT_START:
            id, values = self.parse_item(name[:-1])
            assert id not in items
            items[id] = values
        self.element_end(name)
        return items

    def parse_item(self, name):
        attrs = self.element_start(name)
        id = int(attrs['id'])
        values = self.parse_values()
        self.element_end(name)
        return id, values

    def parse_values(self):
        values = {}
        while self.token.type == XML_ELEMENT_START:
            name = self.token.name_or_data
            value = self.parse_value(name)
            assert name not in values
            values[name] = value
        return values

    def parse_value(self, tag):
        self.element_start(tag)
        value = self.character_data()
        self.element_end(tag)
        if value.isdigit():
            return int(value)
        if value.startswith('"') and value.endswith('"'):
            return value[1:-1]
        return value

    def build_profile(self, objects, nodes):
        profile = Profile()
        
        profile[SAMPLES] = 0
        for id, object in compat_iteritems(objects):
            # Ignore fake objects (process names, modules, "Everything", "kernel", etc.)
            if object['self'] == 0:
                continue

            function = Function(id, object['name'])
            function[SAMPLES] = object['self']
            profile.add_function(function)
            profile[SAMPLES] += function[SAMPLES]

        for id, node in compat_iteritems(nodes):
            # Ignore fake calls
            if node['self'] == 0:
                continue

            # Find a non-ignored parent
            parent_id = node['parent']
            while parent_id != 0:
                parent = nodes[parent_id]
                caller_id = parent['object']
                if objects[caller_id]['self'] != 0:
                    break
                parent_id = parent['parent']
            if parent_id == 0:
                continue

            callee_id = node['object']

            assert objects[caller_id]['self']
            assert objects[callee_id]['self']

            function = profile.functions[caller_id]

            samples = node['self']
            try:
                call = function.calls[callee_id]
            except KeyError:
                call = Call(callee_id)
                call[SAMPLES2] = samples
                function.add_call(call)
            else:
                call[SAMPLES2] += samples

        # Compute derived events
        profile.validate()
        profile.find_cycles()
        profile.ratio(TIME_RATIO, SAMPLES)
        profile.call_ratios(SAMPLES2)
        profile.integrate(TOTAL_TIME_RATIO, TIME_RATIO)

        return profile


class XPerfParser(Parser):
    """Parser for CSVs generted by XPerf, from Microsoft Windows Performance Tools.
    """

    def __init__(self, stream):
        Parser.__init__(self)
        self.stream = stream
        self.profile = Profile()
        self.profile[SAMPLES] = 0
        self.column = {}

    def parse(self):
        import csv
        reader = csv.reader(
            self.stream, 
            delimiter = ',',
            quotechar = None,
            escapechar = None,
            doublequote = False,
            skipinitialspace = True,
            lineterminator = '\r\n',
            quoting = csv.QUOTE_NONE)
        header = True
        for row in reader:
            if header:
                self.parse_header(row)
                header = False
            else:
                self.parse_row(row)
                
        # compute derived data
        self.profile.validate()
        self.profile.find_cycles()
        self.profile.ratio(TIME_RATIO, SAMPLES)
        self.profile.call_ratios(SAMPLES2)
        self.profile.integrate(TOTAL_TIME_RATIO, TIME_RATIO)

        return self.profile

    def parse_header(self, row):
        for column in range(len(row)):
            name = row[column]
            assert name not in self.column
            self.column[name] = column

    def parse_row(self, row):
        fields = {}
        for name, column in compat_iteritems(self.column):
            value = row[column]
            for factory in int, float:
                try:
                    value = factory(value)
                except ValueError:
                    pass
                else:
                    break
            fields[name] = value
        
        process = fields['Process Name']
        symbol = fields['Module'] + '!' + fields['Function']
        weight = fields['Weight']
        count = fields['Count']

        if process == 'Idle':
            return

        function = self.get_function(process, symbol)
        function[SAMPLES] += weight * count
        self.profile[SAMPLES] += weight * count

        stack = fields['Stack']
        if stack != '?':
            stack = stack.split('/')
            assert stack[0] == '[Root]'
            if stack[-1] != symbol:
                # XXX: some cases the sampled function does not appear in the stack
                stack.append(symbol)
            caller = None
            for symbol in stack[1:]:
                callee = self.get_function(process, symbol)
                if caller is not None:
                    try:
                        call = caller.calls[callee.id]
                    except KeyError:
                        call = Call(callee.id)
                        call[SAMPLES2] = count
                        caller.add_call(call)
                    else:
                        call[SAMPLES2] += count
                caller = callee

    def get_function(self, process, symbol):
        function_id = process + '!' + symbol

        try:
            function = self.profile.functions[function_id]
        except KeyError:
            module, name = symbol.split('!', 1)
            function = Function(function_id, name)
            function.process = process
            function.module = module
            function[SAMPLES] = 0
            self.profile.add_function(function)

        return function


class SleepyParser(Parser):
    """Parser for GNU gprof output.

    See also:
    - http://www.codersnotes.com/sleepy/
    - http://sleepygraph.sourceforge.net/
    """

    stdinInput = False

    def __init__(self, filename):
        Parser.__init__(self)

        from zipfile import ZipFile

        self.database = ZipFile(filename)

        self.symbols = {}
        self.calls = {}

        self.profile = Profile()
    
    _symbol_re = re.compile(
        r'^(?P<id>\w+)' + 
        r'\s+"(?P<module>[^"]*)"' + 
        r'\s+"(?P<procname>[^"]*)"' + 
        r'\s+"(?P<sourcefile>[^"]*)"' + 
        r'\s+(?P<sourceline>\d+)$'
    )

    def openEntry(self, name):
        # Some versions of verysleepy use lowercase filenames
        for database_name in self.database.namelist():
            if name.lower() == database_name.lower():
                name = database_name
                break

        return self.database.open(name, 'rU')

    def parse_symbols(self):
        for line in self.openEntry('Symbols.txt'):
            line = line.decode('UTF-8')

            mo = self._symbol_re.match(line)
            if mo:
                symbol_id, module, procname, sourcefile, sourceline = mo.groups()
    
                function_id = ':'.join([module, procname])

                try:
                    function = self.profile.functions[function_id]
                except KeyError:
                    function = Function(function_id, procname)
                    function.module = module
                    function[SAMPLES] = 0
                    self.profile.add_function(function)

                self.symbols[symbol_id] = function

    def parse_callstacks(self):
        for line in self.openEntry('Callstacks.txt'):
            line = line.decode('UTF-8')

            fields = line.split()
            samples = float(fields[0])
            callstack = fields[1:]

            callstack = [self.symbols[symbol_id] for symbol_id in callstack]

            callee = callstack[0]

            callee[SAMPLES] += samples
            self.profile[SAMPLES] += samples
            
            for caller in callstack[1:]:
                try:
                    call = caller.calls[callee.id]
                except KeyError:
                    call = Call(callee.id)
                    call[SAMPLES2] = samples
                    caller.add_call(call)
                else:
                    call[SAMPLES2] += samples

                callee = caller

    def parse(self):
        profile = self.profile
        profile[SAMPLES] = 0

        self.parse_symbols()
        self.parse_callstacks()

        # Compute derived events
        profile.validate()
        profile.find_cycles()
        profile.ratio(TIME_RATIO, SAMPLES)
        profile.call_ratios(SAMPLES2)
        profile.integrate(TOTAL_TIME_RATIO, TIME_RATIO)

        return profile


class AQtimeTable:

    def __init__(self, name, fields):
        self.name = name

        self.fields = fields
        self.field_column = {}
        for column in range(len(fields)):
            self.field_column[fields[column]] = column
        self.rows = []

    def __len__(self):
        return len(self.rows)

    def __iter__(self):
        for values, children in self.rows:
            fields = {}
            for name, value in zip(self.fields, values):
                fields[name] = value
            children = dict([(child.name, child) for child in children])
            yield fields, children
        raise StopIteration

    def add_row(self, values, children=()):
        self.rows.append((values, children))


class AQtimeParser(XmlParser):

    def __init__(self, stream):
        XmlParser.__init__(self, stream)
        self.tables = {}

    def parse(self):
        self.element_start('AQtime_Results')
        self.parse_headers()
        results = self.parse_results()
        self.element_end('AQtime_Results')
        return self.build_profile(results) 

    def parse_headers(self):
        self.element_start('HEADERS')
        while self.token.type == XML_ELEMENT_START:
            self.parse_table_header()
        self.element_end('HEADERS')

    def parse_table_header(self):
        attrs = self.element_start('TABLE_HEADER')
        name = attrs['NAME']
        id = int(attrs['ID'])
        field_types = []
        field_names = []
        while self.token.type == XML_ELEMENT_START:
            field_type, field_name = self.parse_table_field()
            field_types.append(field_type)
            field_names.append(field_name)
        self.element_end('TABLE_HEADER')
        self.tables[id] = name, field_types, field_names

    def parse_table_field(self):
        attrs = self.element_start('TABLE_FIELD')
        type = attrs['TYPE']
        name = self.character_data()
        self.element_end('TABLE_FIELD')
        return type, name

    def parse_results(self):
        self.element_start('RESULTS')
        table = self.parse_data()
        self.element_end('RESULTS')
        return table

    def parse_data(self):
        rows = []
        attrs = self.element_start('DATA')
        table_id = int(attrs['TABLE_ID'])
        table_name, field_types, field_names = self.tables[table_id]
        table = AQtimeTable(table_name, field_names)
        while self.token.type == XML_ELEMENT_START:
            row, children = self.parse_row(field_types)
            table.add_row(row, children)
        self.element_end('DATA')
        return table

    def parse_row(self, field_types):
        row = [None]*len(field_types)
        children = []
        self.element_start('ROW')
        while self.token.type == XML_ELEMENT_START:
            if self.token.name_or_data == 'FIELD':
                field_id, field_value = self.parse_field(field_types)
                row[field_id] = field_value
            elif self.token.name_or_data == 'CHILDREN':
                children = self.parse_children()
            else:
                raise XmlTokenMismatch("<FIELD ...> or <CHILDREN ...>", self.token)
        self.element_end('ROW')
        return row, children

    def parse_field(self, field_types):
        attrs = self.element_start('FIELD')
        id = int(attrs['ID'])
        type = field_types[id]
        value = self.character_data()
        if type == 'Integer':
            value = int(value)
        elif type == 'Float':
            value = float(value)
        elif type == 'Address':
            value = int(value)
        elif type == 'String':
            pass
        else:
            assert False
        self.element_end('FIELD')
        return id, value

    def parse_children(self):
        children = []
        self.element_start('CHILDREN')
        while self.token.type == XML_ELEMENT_START:
            table = self.parse_data()
            assert table.name not in children
            children.append(table)
        self.element_end('CHILDREN')
        return children

    def build_profile(self, results):
        assert results.name == 'Routines'
        profile = Profile()
        profile[TIME] = 0.0
        for fields, tables in results:
            function = self.build_function(fields)
            children = tables['Children']
            for fields, _ in children:
                call = self.build_call(fields)
                function.add_call(call)
            profile.add_function(function)
            profile[TIME] = profile[TIME] + function[TIME]
        profile[TOTAL_TIME] = profile[TIME]
        profile.ratio(TOTAL_TIME_RATIO, TOTAL_TIME)
        return profile
    
    def build_function(self, fields):
        function = Function(self.build_id(fields), self.build_name(fields))
        function[TIME] = fields['Time']
        function[TOTAL_TIME] = fields['Time with Children']
        #function[TIME_RATIO] = fields['% Time']/100.0
        #function[TOTAL_TIME_RATIO] = fields['% with Children']/100.0
        return function

    def build_call(self, fields):
        call = Call(self.build_id(fields))
        call[TIME] = fields['Time']
        call[TOTAL_TIME] = fields['Time with Children']
        #call[TIME_RATIO] = fields['% Time']/100.0
        #call[TOTAL_TIME_RATIO] = fields['% with Children']/100.0
        return call

    def build_id(self, fields):
        return ':'.join([fields['Module Name'], fields['Unit Name'], fields['Routine Name']])

    def build_name(self, fields):
        # TODO: use more fields
        return fields['Routine Name']


class PstatsParser:
    """Parser python profiling statistics saved with te pstats module."""

    stdinInput = False
    multipleInput = True

    def __init__(self, *filename):
        import pstats
        try:
            self.stats = pstats.Stats(*filename)
        except ValueError:
            if sys.version_info[0] >= 3:
                raise
            import hotshot.stats
            self.stats = hotshot.stats.load(filename[0])
        self.profile = Profile()
        self.function_ids = {}

    def get_function_name(self, key):
        filename, line, name = key
        module = os.path.splitext(filename)[0]
        module = os.path.basename(module)
        return "%s:%d:%s" % (module, line, name)

    def get_function(self, key):
        try:
            id = self.function_ids[key]
        except KeyError:
            id = len(self.function_ids)
            name = self.get_function_name(key)
            function = Function(id, name)
            self.profile.functions[id] = function
            self.function_ids[key] = id
        else:
            function = self.profile.functions[id]
        return function

    def parse(self):
        self.profile[TIME] = 0.0
        self.profile[TOTAL_TIME] = self.stats.total_tt
        for fn, (cc, nc, tt, ct, callers) in compat_iteritems(self.stats.stats):
            callee = self.get_function(fn)
            callee.called = nc
            callee[TOTAL_TIME] = ct
            callee[TIME] = tt
            self.profile[TIME] += tt
            self.profile[TOTAL_TIME] = max(self.profile[TOTAL_TIME], ct)
            for fn, value in compat_iteritems(callers):
                caller = self.get_function(fn)
                call = Call(callee.id)
                if isinstance(value, tuple):
                    for i in xrange(0, len(value), 4):
                        nc, cc, tt, ct = value[i:i+4]
                        if CALLS in call:
                            call[CALLS] += cc
                        else:
                            call[CALLS] = cc

                        if TOTAL_TIME in call:
                            call[TOTAL_TIME] += ct
                        else:
                            call[TOTAL_TIME] = ct

                else:
                    call[CALLS] = value
                    call[TOTAL_TIME] = ratio(value, nc)*ct

                caller.add_call(call)
        #self.stats.print_stats()
        #self.stats.print_callees()

        # Compute derived events
        self.profile.validate()
        self.profile.ratio(TIME_RATIO, TIME)
        self.profile.ratio(TOTAL_TIME_RATIO, TOTAL_TIME)

        return self.profile


class Theme:

    def __init__(self, 
            bgcolor = (0.0, 0.0, 1.0),
            mincolor = (0.0, 0.0, 0.0),
            maxcolor = (0.0, 0.0, 1.0),
            fontname = "Arial",
            fontcolor = "white",
            nodestyle = "filled",
            minfontsize = 10.0,
            maxfontsize = 10.0,
            minpenwidth = 0.5,
            maxpenwidth = 4.0,
            gamma = 2.2,
            skew = 1.0):
        self.bgcolor = bgcolor
        self.mincolor = mincolor
        self.maxcolor = maxcolor
        self.fontname = fontname
        self.fontcolor = fontcolor
        self.nodestyle = nodestyle
        self.minfontsize = minfontsize
        self.maxfontsize = maxfontsize
        self.minpenwidth = minpenwidth
        self.maxpenwidth = maxpenwidth
        self.gamma = gamma
        self.skew = skew

    def graph_bgcolor(self):
        return self.hsl_to_rgb(*self.bgcolor)

    def graph_fontname(self):
        return self.fontname

    def graph_fontcolor(self):
        return self.fontcolor

    def graph_fontsize(self):
        return self.minfontsize

    def node_bgcolor(self, weight):
        return self.color(weight)

    def node_fgcolor(self, weight):
        if self.nodestyle == "filled":
            return self.graph_bgcolor()
        else:
            return self.color(weight)

    def node_fontsize(self, weight):
        return self.fontsize(weight)

    def node_style(self):
        return self.nodestyle

    def edge_color(self, weight):
        return self.color(weight)

    def edge_fontsize(self, weight):
        return self.fontsize(weight)

    def edge_penwidth(self, weight):
        return max(weight*self.maxpenwidth, self.minpenwidth)

    def edge_arrowsize(self, weight):
        return 0.5 * math.sqrt(self.edge_penwidth(weight))

    def fontsize(self, weight):
        return max(weight**2 * self.maxfontsize, self.minfontsize)

    def color(self, weight):
        weight = min(max(weight, 0.0), 1.0)
    
        hmin, smin, lmin = self.mincolor
        hmax, smax, lmax = self.maxcolor
        
        if self.skew < 0:
            raise ValueError("Skew must be greater than 0")
        elif self.skew == 1.0:
            h = hmin + weight*(hmax - hmin)
            s = smin + weight*(smax - smin)
            l = lmin + weight*(lmax - lmin)
        else:
            base = self.skew
            h = hmin + ((hmax-hmin)*(-1.0 + (base ** weight)) / (base - 1.0))
            s = smin + ((smax-smin)*(-1.0 + (base ** weight)) / (base - 1.0))
            l = lmin + ((lmax-lmin)*(-1.0 + (base ** weight)) / (base - 1.0))

        return self.hsl_to_rgb(h, s, l)

    def hsl_to_rgb(self, h, s, l):
        """Convert a color from HSL color-model to RGB.

        See also:
        - http://www.w3.org/TR/css3-color/#hsl-color
        """

        h = h % 1.0
        s = min(max(s, 0.0), 1.0)
        l = min(max(l, 0.0), 1.0)

        if l <= 0.5:
            m2 = l*(s + 1.0)
        else:
            m2 = l + s - l*s
        m1 = l*2.0 - m2
        r = self._hue_to_rgb(m1, m2, h + 1.0/3.0)
        g = self._hue_to_rgb(m1, m2, h)
        b = self._hue_to_rgb(m1, m2, h - 1.0/3.0)

        # Apply gamma correction
        r **= self.gamma
        g **= self.gamma
        b **= self.gamma

        return (r, g, b)

    def _hue_to_rgb(self, m1, m2, h):
        if h < 0.0:
            h += 1.0
        elif h > 1.0:
            h -= 1.0
        if h*6 < 1.0:
            return m1 + (m2 - m1)*h*6.0
        elif h*2 < 1.0:
            return m2
        elif h*3 < 2.0:
            return m1 + (m2 - m1)*(2.0/3.0 - h)*6.0
        else:
            return m1


TEMPERATURE_COLORMAP = Theme(
    mincolor = (2.0/3.0, 0.80, 0.25), # dark blue
    maxcolor = (0.0, 1.0, 0.5), # satured red
    gamma = 1.0
)

PINK_COLORMAP = Theme(
    mincolor = (0.0, 1.0, 0.90), # pink
    maxcolor = (0.0, 1.0, 0.5), # satured red
)

GRAY_COLORMAP = Theme(
    mincolor = (0.0, 0.0, 0.85), # light gray
    maxcolor = (0.0, 0.0, 0.0), # black
)

BW_COLORMAP = Theme(
    minfontsize = 8.0,
    maxfontsize = 24.0,
    mincolor = (0.0, 0.0, 0.0), # black
    maxcolor = (0.0, 0.0, 0.0), # black
    minpenwidth = 0.1,
    maxpenwidth = 8.0,
)

PRINT_COLORMAP = Theme(
    minfontsize = 18.0,
    maxfontsize = 30.0,
    fontcolor = "black",
    nodestyle = "solid",
    mincolor = (0.0, 0.0, 0.0), # black
    maxcolor = (0.0, 0.0, 0.0), # black
    minpenwidth = 0.1,
    maxpenwidth = 8.0,
)


class DotWriter:
    """Writer for the DOT language.

    See also:
    - "The DOT Language" specification
      http://www.graphviz.org/doc/info/lang.html
    """

    strip = False
    wrap = False

    def __init__(self, fp):
        self.fp = fp

    def wrap_function_name(self, name):
        """Split the function name on multiple lines."""

        if len(name) > 32:
            ratio = 2.0/3.0
            height = max(int(len(name)/(1.0 - ratio) + 0.5), 1)
            width = max(len(name)/height, 32)
            # TODO: break lines in symbols
            name = textwrap.fill(name, width, break_long_words=False)

        # Take away spaces
        name = name.replace(", ", ",")
        name = name.replace("> >", ">>")
        name = name.replace("> >", ">>") # catch consecutive

        return name

    show_function_events = [TOTAL_TIME_RATIO, TIME_RATIO]
    show_edge_events = [TOTAL_TIME_RATIO, CALLS]

    def graph(self, profile, theme):
        self.begin_graph()

        fontname = theme.graph_fontname()
        fontcolor = theme.graph_fontcolor()
        nodestyle = theme.node_style()

        self.attr('graph', fontname=fontname, ranksep=0.25, nodesep=0.125)
        self.attr('node', fontname=fontname, shape="box", style=nodestyle, fontcolor=fontcolor, width=0, height=0)
        self.attr('edge', fontname=fontname)

        for function in compat_itervalues(profile.functions):
            labels = []
            if function.process is not None:
                labels.append(function.process)
            if function.module is not None:
                labels.append(function.module)

            if self.strip:
                function_name = function.stripped_name()
            else:
                function_name = function.name
            if self.wrap:
                function_name = self.wrap_function_name(function_name)
            labels.append(function_name)

            for event in self.show_function_events:
                if event in function.events:
                    label = event.format(function[event])
                    labels.append(label)
            if function.called is not None:
                labels.append("%u%s" % (function.called, MULTIPLICATION_SIGN))

            if function.weight is not None:
                weight = function.weight
            else:
                weight = 0.0

            label = '\n'.join(labels)
            self.node(function.id, 
                label = label, 
                color = self.color(theme.node_bgcolor(weight)), 
                fontcolor = self.color(theme.node_fgcolor(weight)), 
                fontsize = "%.2f" % theme.node_fontsize(weight),
            )

            for call in compat_itervalues(function.calls):
                callee = profile.functions[call.callee_id]

                labels = []
                for event in self.show_edge_events:
                    if event in call.events:
                        label = event.format(call[event])
                        labels.append(label)

                if call.weight is not None:
                    weight = call.weight
                elif callee.weight is not None:
                    weight = callee.weight
                else:
                    weight = 0.0

                label = '\n'.join(labels)

                self.edge(function.id, call.callee_id, 
                    label = label, 
                    color = self.color(theme.edge_color(weight)), 
                    fontcolor = self.color(theme.edge_color(weight)),
                    fontsize = "%.2f" % theme.edge_fontsize(weight), 
                    penwidth = "%.2f" % theme.edge_penwidth(weight), 
                    labeldistance = "%.2f" % theme.edge_penwidth(weight), 
                    arrowsize = "%.2f" % theme.edge_arrowsize(weight),
                )

        self.end_graph()

    def begin_graph(self):
        self.write('digraph {\n')

    def end_graph(self):
        self.write('}\n')

    def attr(self, what, **attrs):
        self.write("\t")
        self.write(what)
        self.attr_list(attrs)
        self.write(";\n")

    def node(self, node, **attrs):
        self.write("\t")
        self.id(node)
        self.attr_list(attrs)
        self.write(";\n")

    def edge(self, src, dst, **attrs):
        self.write("\t")
        self.id(src)
        self.write(" -> ")
        self.id(dst)
        self.attr_list(attrs)
        self.write(";\n")

    def attr_list(self, attrs):
        if not attrs:
            return
        self.write(' [')
        first = True
        for name, value in compat_iteritems(attrs):
            if first:
                first = False
            else:
                self.write(", ")
            self.id(name)
            self.write('=')
            self.id(value)
        self.write(']')

    def id(self, id):
        if isinstance(id, (int, float)):
            s = str(id)
        elif isinstance(id, basestring):
            if id.isalnum() and not id.startswith('0x'):
                s = id
            else:
                s = self.escape(id)
        else:
            raise TypeError
        self.write(s)

    def color(self, rgb):
        r, g, b = rgb

        def float2int(f):
            if f <= 0.0:
                return 0
            if f >= 1.0:
                return 255
            return int(255.0*f + 0.5)

        return "#" + "".join(["%02x" % float2int(c) for c in (r, g, b)])

    def escape(self, s):
        if not PYTHON_3:
            s = s.encode('utf-8')
        s = s.replace('\\', r'\\')
        s = s.replace('\n', r'\n')
        s = s.replace('\t', r'\t')
        s = s.replace('"', r'\"')
        return '"' + s + '"'

    def write(self, s):
        self.fp.write(s)


class Main:
    """Main program."""

    themes = {
            "color": TEMPERATURE_COLORMAP,
            "pink": PINK_COLORMAP,
            "gray": GRAY_COLORMAP,
            "bw": BW_COLORMAP,
            "print": PRINT_COLORMAP,
    }

    formats = {
        "aqtime": AQtimeParser,
        "axe": AXEParser,
        "callgrind": CallgrindParser,
        "hprof": HProfParser,
        "oprofile": OprofileParser,
        "perf": PerfParser,
        "prof": GprofParser,
        "pstats": PstatsParser,
        "sleepy": SleepyParser,
        "sysprof": SysprofParser,
        "xperf": XPerfParser,
    }

    def naturalJoin(self, values):
        if len(values) >= 2:
            return ', '.join(values[:-1]) + ' or ' + values[-1]

        else:
            return ''.join(values)

    def main(self):
        """Main program."""

        global totalMethod

        formatNames = list(self.formats.keys())
        formatNames.sort()

        optparser = optparse.OptionParser(
            usage="\n\t%prog [options] [file] ...")
        optparser.add_option(
            '-o', '--output', metavar='FILE',
            type="string", dest="output",
            help="output filename [stdout]")
        optparser.add_option(
            '-n', '--node-thres', metavar='PERCENTAGE',
            type="float", dest="node_thres", default=0.5,
            help="eliminate nodes below this threshold [default: %default]")
        optparser.add_option(
            '-e', '--edge-thres', metavar='PERCENTAGE',
            type="float", dest="edge_thres", default=0.1,
            help="eliminate edges below this threshold [default: %default]")
        optparser.add_option(
            '-f', '--format',
            type="choice", choices=formatNames,
            dest="format", default="prof",
            help="profile format: %s [default: %%default]" % self.naturalJoin(formatNames))
        optparser.add_option(
            '--total',
            type="choice", choices=('callratios', 'callstacks'),
            dest="totalMethod", default=totalMethod,
            help="preferred method of calculating total time: callratios or callstacks (currently affects only perf format) [default: %default]")
        optparser.add_option(
            '-c', '--colormap',
            type="choice", choices=('color', 'pink', 'gray', 'bw', 'print'),
            dest="theme", default="color",
            help="color map: color, pink, gray, bw, or print [default: %default]")
        optparser.add_option(
            '-s', '--strip',
            action="store_true",
            dest="strip", default=False,
            help="strip function parameters, template parameters, and const modifiers from demangled C++ function names")
        optparser.add_option(
            '-w', '--wrap',
            action="store_true",
            dest="wrap", default=False,
            help="wrap function names")
        optparser.add_option(
            '--show-samples',
            action="store_true",
            dest="show_samples", default=False,
            help="show function samples")
        # add option to create subtree or show paths
        optparser.add_option(
            '-z', '--root',
            type="string",
            dest="root", default="",
            help="prune call graph to show only descendants of specified root function")
        optparser.add_option(
            '-l', '--leaf',
            type="string",
            dest="leaf", default="",
            help="prune call graph to show only ancestors of specified leaf function")
        # add a new option to control skew of the colorization curve
        optparser.add_option(
            '--skew',
            type="float", dest="theme_skew", default=1.0,
            help="skew the colorization curve.  Values < 1.0 give more variety to lower percentages.  Values > 1.0 give less variety to lower percentages")
        (self.options, self.args) = optparser.parse_args(sys.argv[1:])

        if len(self.args) > 1 and self.options.format != 'pstats':
            optparser.error('incorrect number of arguments')

        try:
            self.theme = self.themes[self.options.theme]
        except KeyError:
            optparser.error('invalid colormap \'%s\'' % self.options.theme)
        
        # set skew on the theme now that it has been picked.
        if self.options.theme_skew:
            self.theme.skew = self.options.theme_skew
            
        totalMethod = self.options.totalMethod

        try:
            Format = self.formats[self.options.format]
        except KeyError:
            optparser.error('invalid format \'%s\'' % self.options.format)

        if Format.stdinInput:
            if not self.args:
                fp = sys.stdin
            else:
                fp = open(self.args[0], 'rt')
            parser = Format(fp)
        elif Format.multipleInput:
            if not self.args:
                optparser.error('at least a file must be specified for %s input' % self.options.format)
            parser = Format(*self.args)
        else:
            if len(self.args) != 1:
                optparser.error('exactly one file must be specified for %s input' % self.options.format)
            parser = Format(self.args[0])

        self.profile = parser.parse()
        
        if self.options.output is None:
            self.output = sys.stdout
        else:
            if PYTHON_3:
                self.output = open(self.options.output, 'wt', encoding='UTF-8')
            else:
                self.output = open(self.options.output, 'wt')

        self.write_graph()

    def write_graph(self):
        dot = DotWriter(self.output)
        dot.strip = self.options.strip
        dot.wrap = self.options.wrap
        if self.options.show_samples:
            dot.show_function_events.append(SAMPLES)

        profile = self.profile
        profile.prune(self.options.node_thres/100.0, self.options.edge_thres/100.0)
        
        if self.options.root:
            rootId = profile.getFunctionId(self.options.root)
            if not rootId:
                sys.stderr.write('root node ' + self.options.root + ' not found (might already be pruned : try -e0 -n0 flags)\n')
                sys.exit(1)
            profile.prune_root(rootId)
        if self.options.leaf:
            leafId = profile.getFunctionId(self.options.leaf)
            if not leafId:
                sys.stderr.write('leaf node ' + self.options.leaf + ' not found (maybe already pruned : try -e0 -n0 flags)\n')
                sys.exit(1)
            profile.prune_leaf(leafId)

        dot.graph(profile, self.theme)


if __name__ == '__main__':
    Main().main()
