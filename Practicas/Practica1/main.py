import lexico
import os

class Manager:

    def build_automaton():
        automaton = lexico.Automaton()
        Manager.insert_data(automaton)
        has_missing_transitions = False
        for state in automaton.states:
            for simbol in automaton.alphabet:
                destiny = automaton.transitions[state].get(simbol, None)
                if destiny == None:
                    has_missing_transitions = True
                    break
            if has_missing_transitions:
                break
        if not has_missing_transitions:
            return automaton
        pool = automaton.num_states()
        automaton.add_state(pool, False, False)
        for state in automaton.states:
            for simbol in automaton.alphabet:
                destiny = automaton.transitions[state].get(simbol, None)
                if destiny == None:
                    automaton.add_transition(state, simbol, pool)
            automaton.add_state(pool, simbol, pool)
        return automaton

    def build_non_det_automaton():
        automaton = lexico.NonDetAutomaton()
        Manager.insert_data(automaton)
        return automaton

    def insert_data(automaton):
        while True:
            os.system('clear')
            print('1. Insert state')
            print('2. Insert transition')
            print('3. Exit')
            option = input('Your option: ')
            if option == '1':
                print('Enter <label> <is initial> <is final>')
                data = input().split()
                label = int(data[0])
                is_initial = data[1].lower() in {'true', '1', 'yes'}
                is_final = data[2].lower() in {'true', '1', 'yes'}
                # print(label, is_initial, is_final)
                automaton.add_state(label, is_initial, is_final)
            elif option == '2':
                print('Enter <origin> <simbol> <destiny>')
                data = input().split()
                origin = int(data[0])
                simbol = str(data[1])
                destiny = int(data[2])
                automaton.add_transition(origin, simbol, destiny)
            else:
                break
            print(automaton)
            input('Press enter to continue')

    def make_img(automaton, draw_pool_state = False):
        file = open('automaton.gv', 'w')
        file.write(automaton.to_graphviz(draw_pool_state))
        file.close()
        os.system('dot automaton.gv -Tpng > output.png')
        os.system('eog output.png')

def main():
    while True:
        os.system('clear')
        print('Options:')
        print('\t1. Thompson construction')
        print('\t2. Subset algorithm')
        print('\t3. Regular expression to Automaton')
        print('\t4. Minimum equivalent automaton')
        print('\t5. Exit')
        option = input('Your option: ')
        if option == '1':
            regex = input('Enter the regular expression: ')
            regex_obj = lexico.RegularExpression(regex)
            automaton = regex_obj.thompson_construction()
            # print(automaton)
            Manager.make_img(automaton)
        elif option == '2':
            suboption = input('Enter automaton (1) or regular expression (2)?: ')
            if suboption == '1':
                non_det_automaton = Manager.build_non_det_automaton()
            else:
                regex = input('Enter the regular expression: ')
                regex_obj = lexico.RegularExpression(regex)
                non_det_automaton = regex_obj.thompson_construction()
            Manager.make_img(non_det_automaton)
            automaton = non_det_automaton.subset_construction()
            Manager.make_img(automaton)
        elif option == '3':
            regex = input('Enter the regular expression: ')
            regex_obj = lexico.RegularExpression(regex)
            automaton = regex_obj.create_automaton()
            # print(automaton)
            Manager.make_img(automaton)
        elif option == '4':
            suboption = input('Enter automaton (1) or regular expression (2)?: ')
            if suboption == '1':
                automaton = Manager.build_automaton()
            else:
                regex = input('Enter the regular expression: ')
                regex_obj = lexico.RegularExpression(regex)
                automaton = regex_obj.create_automaton()
            Manager.make_img(automaton)
            min_automaton = automaton.create_minimum()
            # print(min_automaton)
            Manager.make_img(min_automaton)
        else:
            break
        input('Press enter to continue')

if __name__ == '__main__':
    main()
