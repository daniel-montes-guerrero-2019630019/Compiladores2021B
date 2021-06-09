class Automaton:

    def __init__(self):
        self.initial = None
        self.states = set()
        self.alphabet = set()
        self.transitions = {}
        self.final_states = set()

    def num_states(self):
        return len(self.states)

    def copy(self, offset):
        """ creates a copy of the automaton, the state labels are shifted by offset """
        new_automaton = Automaton()
        if isinstance(self, NonDetAutomaton):
            new_automaton = NonDetAutomaton()
        new_automaton.initial = self.initial + offset
        for state in self.states:
            new_automaton.add_state(state + offset, state == self.initial, state in self.final_states)
        for origin in self.states:
            for simbol, destiny in self.transitions[origin].items():
                if isinstance(destiny, list):
                    for dest_state in destiny:
                        new_automaton.add_transition(origin + offset, simbol, dest_state + offset)
                else:
                    new_automaton.add_transition(origin + offset, simbol, destiny + offset)
        return new_automaton

    def add_state(self, state, is_initial = False, is_final = False):
        """ adds a new state to the automaton """
        if state in self.states:
            return False
        self.states.add(state)
        self.transitions[state] = {}
        if is_initial:
            self.initial = state
        if is_final:
            self.final_states.add(state)

    def add_transition(self, origin, simbol, destiny):
        """ adds a new transition to the automaton """
        self.alphabet.add(simbol)
        # print('curr alphabet: ', self.alphabet)
        if origin not in self.states:
            raise Exception(f'origin: {origin} not in states')
        if destiny not in self.states:
            raise Exception(f'detiny: {destiny} not in states')
        if isinstance(self, NonDetAutomaton):
            if simbol not in self.transitions[origin]:
                self.transitions[origin][simbol] = []
            self.transitions[origin][simbol].append(destiny)
        else:
            self.transitions[origin][simbol] = destiny

    def dfs_closure(self, state, simbol, visited, closure):
        """ returns the closure for a state and a simbol """
        visited[state] = True
        closure.add(state)
        if isinstance(self.transitions[state].get(simbol, []), list):
            for destiny in self.transitions[state].get(simbol, []):
                if not visited[destiny]:
                    self.dfs_closure(destiny, simbol, visited, closure)
        else:
            destiny = self.transitions[state].get(simbol, -1)
            if destiny != -1 and not visited[destiny]:
                self.dfs_closure(destiny, simbol, visited, closure)

    def check_equivalent(self, state1, state2, is_in_group):
        """ checks if two states are equivalent """
        for simbol in self.alphabet:
            destiny1 = self.transitions[state1].get(simbol, None)
            # destiny1 = self.transitions[state1][simbol]
            destiny2 = self.transitions[state2].get(simbol, None)
            # destiny2 = self.transitions[state2][simbol]
            # if destiny1 == None and destiny2 == None:
            #     continue
            if destiny1 == None or destiny2 == None:
                continue
            if is_in_group[destiny1] != is_in_group[destiny2]:
                return False
        return True

    def create_minimum(self):
        """ creates the minimum equivalent automaton """
        curr_partition = {0: set(), 1 : set()}
        curr_is_in_group = {}
        for state in self.states:
            if state in self.final_states:
                curr_is_in_group[state] = 1
                curr_partition[1].add(state)
            else:
                curr_is_in_group[state] = 0
                curr_partition[0].add(state)
        # divide groups
        # print(curr_partition)
        while True:
            new_partition = {}
            new_is_in_group = {}
            for label, group in curr_partition.items():
                # process every state in the group
                new_groups = {}
                for state in group:
                    if len(new_groups) == 0:
                        new_groups[len(new_groups)] = set([state])
                        continue
                    # search for a group to insert
                    was_inserted = False
                    for sublabel, subgroup in new_groups.items():
                        is_equivalent = True
                        for substate in subgroup:
                            if not self.check_equivalent(state, substate, curr_is_in_group):
                                is_equivalent = False
                                break
                        if is_equivalent:
                            was_inserted = True
                            new_groups[sublabel].add(state)
                            break
                    if not was_inserted:
                        new_groups[len(new_groups)] = set([state])
                # insert the created groups
                for sublabel, subgroup in new_groups.items():
                    for state in subgroup:
                        new_is_in_group[state] = len(new_partition)
                    new_partition[len(new_partition)] = subgroup.copy()
            if len(curr_partition) == len(new_partition):
                break
            # print(new_partition)
            curr_partition = new_partition
            curr_is_in_group = new_is_in_group
        # build automaton
        representative = {}
        automaton = Automaton()
        for label, group in curr_partition.items():
            is_initial = self.initial in group
            is_final = not group.isdisjoint(self.final_states)
            automaton.add_state(label, is_initial, is_final)
            for state in group:
                representative[label] = state
        for origin, group in curr_partition.items():
            org_state = representative[origin]
            for simbol in self.alphabet:
                org_destiny = self.transitions[org_state].get(simbol, None)
                if org_destiny == None:
                    continue
                # org_destiny = self.transitions[org_state][simbol]
                destiny = curr_is_in_group[org_destiny]
                automaton.add_transition(origin, simbol, destiny)
        return automaton

    def is_pool_state(self, state):
        for simbol in self.alphabet:
            destiny = self.transitions[state].get(simbol, None)
            if (destiny == None) or (destiny != state):
                return False
        return True

    def to_graphviz(self, draw_pool_state = False):
        valid_states = set()
        data = 'digraph automaton {\n'
        data += '\trankdir = LR;'
        data += '\n\tinit [shape = point];\n'
        data += '\tratio = auto;\n'
        for state in self.states:
            if not draw_pool_state and self.is_pool_state(state):
                continue
            data += f'\t{state} [shape = circle'
            if state in self.final_states:
                data += ', peripheries = 2'
            data += '];\n'
            valid_states.add(state)
        data += f'\tinit -> {self.initial};\n'
        for origin in self.states:
            for simbol, destiny in self.transitions[origin].items():
                if isinstance(destiny, list):
                    for dest_state in destiny:
                        if origin in valid_states and dest_state in valid_states:
                            data += f'\t{origin} -> {dest_state} [label = "{simbol}"];\n'
                else:
                    if origin in valid_states and destiny in valid_states:
                        data += f'\t{origin} -> {destiny} [label = "{simbol}"];\n'
        data += '}'
        return data

    def __str__(self):
        return ('{\n'
            + f'\tinitial : {self.initial},\n'
            + f'\tstates : {self.states},\n'
            + f'\talphabet: {self.alphabet},\n'
            + f'\ttransitions : {self.transitions},\n'
            + f'\tfinal_states : {self.final_states}\n'
            + '}')

class NonDetAutomaton(Automaton):

    def join(self, automaton, initial = None, join_finals = False):
        """ inserts into the automaton all the states and transitions of automaton """
        # for state in self.states:
        #     if state in automaton.states:
        #         raise Exception(f'state: {state} is duplicated, cannot join')
        if initial != None:
            self.initial = initial
        self.states |= automaton.states
        self.alphabet |= automaton.alphabet
        if join_finals:
            self.final_states |= automaton.final_states
        self.transitions = {**self.transitions, **automaton.transitions}

    def thompson_union(a, b):
        """ thompson union template """
        new_automaton = NonDetAutomaton()
        initial_id = 0
        final_id = 1 + a.num_states() + b.num_states()
        new_automaton.add_state(initial_id, True, False)
        tmp_a = a.copy(1)
        tmp_b = b.copy(1 + a.num_states())
        new_automaton.join(tmp_a)
        new_automaton.join(tmp_b)
        new_automaton.add_state(final_id, False, True)
        assert len(tmp_a.final_states) == 1
        assert len(tmp_b.final_states) == 1
        new_automaton.add_transition(initial_id, RegularExpression.EPSILON, tmp_a.initial)
        for i in tmp_a.final_states:
            tmp_final = i
        new_automaton.add_transition(tmp_final, RegularExpression.EPSILON, final_id)
        new_automaton.add_transition(initial_id, RegularExpression.EPSILON, tmp_b.initial)
        for i in tmp_b.final_states:
            tmp_final = i
        new_automaton.add_transition(tmp_final, RegularExpression.EPSILON, final_id)
        return new_automaton

    def thompson_base(simbol):
        """ thompson base template """
        new_automaton = NonDetAutomaton()
        new_automaton.add_state(0, True, False)
        new_automaton.add_state(1, False, True)
        new_automaton.add_transition(0, simbol, 1)
        return new_automaton

    def thompson_concat(a, b):
        """ thompson concatenation template """
        new_automaton = a.copy(0)
        tmp_b = b.copy(a.num_states() - 1)
        new_automaton.final_states.clear()
        new_automaton.join(tmp_b, None, True)
        return new_automaton

    def thompson_kleene_star(a):
        """ thompson kleene star template """
        new_automaton = NonDetAutomaton()
        initial_id = 0
        final_id = a.num_states() + 1
        new_automaton.add_state(initial_id, True, False)
        tmp_a = a.copy(1)
        new_automaton.add_state(final_id, False, True)
        new_automaton.join(tmp_a)
        new_automaton.add_transition(initial_id, RegularExpression.EPSILON, tmp_a.initial)
        for i in tmp_a.final_states:
            tmp_final = i
        new_automaton.add_transition(tmp_final, RegularExpression.EPSILON, tmp_a.initial)
        new_automaton.add_transition(tmp_final, RegularExpression.EPSILON, final_id)
        new_automaton.add_transition(initial_id, RegularExpression.EPSILON, final_id)
        return new_automaton

    def epsilon_closure(self, state):
        """ returns the epsilon closure for a state """
        visited = [False] * self.num_states()
        closure = set()
        if isinstance(state, set):
            for i in state:
                self.dfs_closure(i, RegularExpression.EPSILON, visited, closure)
        else:
            self.dfs_closure(state, RegularExpression.EPSILON, visited, closure)
        return closure

    def move(self, states, simbol):
        """ returns the state of moving a state with a simbol """
        tmp_state = set()
        for state in states:
            destinations = self.transitions[state].get(simbol, [])
            for destiny in destinations:
                tmp_state.add(destiny)
        return tmp_state

    def subset_construction(self):
        """ returns the determninistic automaton of this non determninistic automaton """
        new_states = set()
        found_kernels = set()
        new_states_list = []
        new_transitions = []
        labels = {}
        new_initial = self.epsilon_closure(self.initial)
        new_states.add(frozenset(new_initial))
        new_states_list.append(frozenset(new_initial))
        labels[frozenset(new_initial)] = 0
        new_automaton = Automaton()
        # print(new_initial)
        index = 0
        # process every state
        while index < len(new_states_list):
            curr_state = new_states_list[index]
            for simbol in self.alphabet:
                if simbol == RegularExpression.EPSILON:
                    continue
                kernel = self.move(curr_state, simbol)
                # if len(kernel) == 0:
                #     continue
                dest_state = None
                if frozenset(kernel) in found_kernels:
                    dest_state = labels[frozenset(kernel)]
                else:
                    tmp = self.epsilon_closure(kernel)
                    # if len(tmp) == 0:
                    #     continue
                    if frozenset(tmp) in labels:
                        dest_state = labels[frozenset(tmp)]
                    else:
                        dest_state = len(new_states_list)
                        new_states_list.append(frozenset(tmp))
                        new_states.add(frozenset(tmp))
                    found_kernels.add(frozenset(kernel))
                    labels[frozenset(kernel)] = dest_state
                    labels[frozenset(tmp)] = dest_state
                new_transitions.append([labels[curr_state], simbol, dest_state])
            index += 1
        for state in new_states_list:
            is_initial = state == new_initial
            is_final = not set(state).isdisjoint(self.final_states)
            new_automaton.add_state(labels[state], is_initial, is_final)
        for transition in new_transitions:
            new_automaton.add_transition(transition[0], transition[1], transition[2])
        return new_automaton


class RegularExpression:
    EPSILON = 'e'
    SEPARATOR = '#'
    priority = {'(' : 1, ')' : 1, '*' : 0,'°' : 3, '|' : 2}

    def __init__(self, regular_expression):
        self.regular_expression = regular_expression

    def thompson_construction(self):
        """ returns the non determninistic automaton equivalent to the regular expression """
        self.mark_concatenations()
        reg_expr = self.infix_to_postfix()
        # print(reg_expr)
        stack = []
        for character in reg_expr:
            if RegularExpression.is_simbol(character):
                stack.append(NonDetAutomaton.thompson_base(character))
            elif character == '*':
                stack[-1] = NonDetAutomaton.thompson_kleene_star(stack[-1])
            else:
                tmp_b = stack.pop()
                tmp_a = stack.pop()
                if character == '|':
                    stack.append(NonDetAutomaton.thompson_union(tmp_a, tmp_b))
                else:
                    stack.append(NonDetAutomaton.thompson_concat(tmp_a, tmp_b))
        return stack[0]

    def is_simbol(character):
        """ checks if the character is a simbol """
        return character not in {'|', '(', ')', '°', '*'}

    def mark_concatenations(self):
        """ inserts the concat operator into the expression """
        new_reg_expr = ''
        new_reg_expr += self.regular_expression[0]
        for i in range(1, len(self.regular_expression)):
            current_char = self.regular_expression[i]
            previous_char = self.regular_expression[i - 1]
            check_curr = RegularExpression.is_simbol(current_char) or current_char == '('
            prev_is_simbol = RegularExpression.is_simbol(previous_char)
            if (check_curr) and (prev_is_simbol or previous_char in {'*', ')'}):
                new_reg_expr += '°'
            new_reg_expr += current_char
        self.regular_expression = new_reg_expr

    def infix_to_postfix(self):
        """ returns the postfix form of the expression """
        stack = []
        index = 0
        postfix_expresion = ''
        while index < len(self.regular_expression):
            current_char = self.regular_expression[index]
            if current_char == '(':
                stack.append('(')
            elif current_char == ')':
                while len(stack) > 0:
                    tmp = stack.pop()
                    if tmp == '(':
                        break
                    postfix_expresion += tmp
            elif RegularExpression.is_simbol(current_char) or current_char == '*':
                postfix_expresion += current_char
            else:
                if len(stack) == 0 or self.priority[current_char] > self.priority[stack[-1]]:
                    stack.append(current_char)
                else:
                    postfix_expresion += stack.pop()
                    index -= 1
            index += 1
            # print(postfix_expresion, self.regular_expression)
        while len(stack):
            postfix_expresion += stack.pop()
        return postfix_expresion

    def create_parse_tree(self):
        """ returns the root of the parse tree of the expression """
        self.regular_expression = '(' + self.regular_expression + ')' + self.SEPARATOR
        self.mark_concatenations()
        reg_expr = self.infix_to_postfix()
        # print(reg_expr)
        stack = []
        index = 0
        for character in reg_expr:
            node = ParseTreeNode()
            node.value = character
            node.index = index
            if character == '*':
                node.left = stack.pop()
            elif not RegularExpression.is_simbol(character):
                node.right = stack.pop()
                node.left = stack.pop()
            else:
                index += 1
            stack.append(node)
        return stack[0]

    def create_automaton(self):
        """ return the equivalent determninistic automaton """
        tree = self.create_parse_tree()
        automaton = tree.create_automaton()
        return automaton

class ParseTreeNode:

    def __init__(self, left = None, right = None, value = None, index = None):
        self.left = left
        self.right = right
        self.value = value
        self.index = index
        self.avoidable = False
        self.initials = set()
        self.finals = set()

    def is_leaf(self):
        """ return true if the node is a leaf """
        return self.left == None and self.right == None

    def create_automaton(self):
        """ creates the equivalent automaton for the expression represented by the parse tree """
        alphabet = set()
        next_table = []
        value = {}
        transitions = []
        labels = {}
        automaton = Automaton()
        self.build(next_table, alphabet, value)
        states = set()
        states_list = []
        labels[frozenset(self.initials)] = 0
        states_list.append(frozenset(self.initials))
        states.add(frozenset(self.initials))
        index = 0
        while index < len(states_list):
            for simbol in alphabet:
                if simbol == RegularExpression.SEPARATOR:
                    continue
                tmp = set()
                for state in states_list[index]:
                    if value[state] == simbol:
                        while len(next_table) <= state:
                            next_table.append(set())
                        tmp |= next_table[state]
                # if len(tmp) == 0:
                #     continue
                if tmp not in states:
                    labels[frozenset(tmp)] = len(states_list)
                    states.add(frozenset(tmp))
                    states_list.append(frozenset(tmp))
                transitions.append([states_list[index], simbol, frozenset(tmp)])
            index += 1
        for state in range(index):
            is_initial = state == 0
            is_final = self.left.index in states_list[state]
            automaton.add_state(state, is_initial, is_final)
        for origin, simbol, destiny in transitions:
            automaton.add_transition(labels[origin], simbol, labels[destiny])
        # print(next_table)
        return automaton

    def build(self, next_table, alphabet, value):
        """ builds the parse tree """
        if self.is_leaf():
            alphabet.add(self.value)
            value[self.index] = self.value
            self.initials.add(self.index)
            self.finals.add(self.index)
            return
        if self.left:
            self.left.build(next_table, alphabet, value)
        if self.right:
            self.right.build(next_table, alphabet, value)
        # avoidable
        if self.value == '*':
            self.avoidable = True
        elif self.value == '|':
            self.avoidable = self.left.avoidable or self.right.avoidable
        elif self.value == '°':
            self.avoidable = self.left.avoidable and self.right.avoidable
        # initials
        self.initials = self.left.initials.copy()
        if (self.left.avoidable and self.value == '°') or self.value == '|':
            self.initials |= self.right.initials
        # finals
        if self.value == '*':
            self.finals = self.left.finals.copy()
        else:
            # print(self.value, self.index)
            self.finals = self.right.finals.copy()
            if (self.right.avoidable and self.value == '°') or self.value == '|':
                self.finals |= self.left.finals
        # next table
        if self.value == '°':
            for last in self.left.finals:
                while len(next_table) <= last:
                    next_table.append(set())
                next_table[last] |= self.right.initials
        elif self.value == '*':
            for last in self.left.finals:
                while len(next_table) <= last:
                    next_table.append(set())
                next_table[last] |= self.left.initials

    def __str__(self):
        return ('{'
            + f'character : {self.value}, '
            + f'index: {self.index}, '
            + f'avoidable: {self.avoidable}, '
            + f'initials: {self.initials}, '
            + f'finals: {self.finals}, '
            + f'left : {self.left}, '
            + f'right: {self.right}'
            + '}')

if __name__ == '__main__':
    # Test
    rg = RegularExpression('(a|ba*)cd')
    c = rg.thompson_construction()
    print(c.to_graphviz())
