%{
	#include <stdio.h>
	#include <stdlib.h>
	#include "symbol_table.h"
	#define _BOOL_ 1
	#define _INT_ 2
	#define _LONG_ 3
	#define _FLOAT_ 4
	#define _DOUBLE_ 5
	#define _CHAR_ 6
	#define _STRING_ 7
	void yyerror(const char* message){
		printf("%s\n", message);
		exit(1);
	}

	int checkTypes(int type1, int type2) {
		if(type1 == type2) return 0;
		printf("estas seguro que sabes programar?!!!\n");
		exit(1);
	}
	void assignUnary(symrec* $$, symrec* $1, int opc);
  	void assignValue(symrec* a, symrec* b, symrec* c, int opc);
%}

%define api.value.type union
%token <symrec*> IDENTIFIER 
%token <symrec*> INT FLOAT DOUBLE LONG BOOL CHAR STRING
%token <symrec*> CONST_CHAR CONST_BOOL CONST_LONG
%token <symrec*> CONST_INT CONST_FLOAT CONST_DOUBLE CONST_STRING
%nterm <symrec*> variable_declaration variable type expression condition constant
%nterm <int> logical_operator

%token FUNCTION
%token MAIN
%token ALGORITHM 
%token PLUSPLUS MINUSMINUS
%token FOR WHILE IF ELSE
%token RULE
%token SET SMARTTILE TILE NAME PATH MAPWIDTH SECTION
%token /*_BEGIN END NEW*/ JOIN CONTAINER
%token <int> GREATER_EQ LESS_EQ AND_OP OR_OP NEQ GREATER LESS

%precedence '='
%left '-' '+'
%left '*' '/'
%precedence NEG

%%
// declaracion inicial main
input
	: %empty
	| set_size initial_declaration main_function
	;
set_size
	: SET '=''{' CONST_INT','CONST_INT'}'';'  { printf("Declaracion de tamanio\n"); }
	;

initial_declaration
	: initial_declaration section   {}
	| initial_declaration smarttile  {}
	| %empty
	;
smarttile
	: SMARTTILE IDENTIFIER '{'tiles_list'}'  {printf("smarttile");}
	;

tiles_list
	: tiles_list tile  {printf("tile_list");}
	| %empty
	;

tile
	: TILE IDENTIFIER '{'tile_content rule'}' {printf("Tile\n");}
	;

section
	: SECTION IDENTIFIER ':' ALGORITHM '{'section_declaration'}'  {printf("Seccion\n"); }
	;

section_declaration
	:  IDENTIFIER'='constant';'  {printf("Declaracion");}
	;

tile_content
	: tile_content IDENTIFIER'='CONST_STRING';'  {printf("Contenido de tile");}
	| %empty
	;

main_function
	: MAIN '{' code_block '}'  { printf("Funcion principal\n"); }
	;

code_block
	: statement ';'            { printf("statement"); }
	| statement ';' code_block { printf("statement code_block"); }
	| error                    { yyerrok; }
	;
rule
	: %empty
	| RULE '=''{' vector','vector','vector'}' {printf("rule\n");}
	;
vector
	: '{'CONST_INT','CONST_INT','CONST_INT'}' {printf("vector\n");}
	;
statement
	: variable_declaration   { printf("variable\n"); }
	| expression             { printf("expresion\n"); }
	| FUNCTION               { printf("funcion\n"); }
	| for                    { printf("for\n"); }
	| while                  { printf("while\n"); }
	| if                     { printf("if\n"); }
	;
/*
 function
	: FUNCTION IDENTIFIER '(' args ')' ' {' statement '}' 		{ printf("Funcion\n"); }
	;
args
	: args ',' args			{ printf("Argumento\n"); }
	| type IDENTIFIER		{ printf("Declaracion\n");}	
	| %empty
	;
*/
variable_declaration
	: type variable '=' expression  {
		if(getsym($2 -> name) != NULL) {
			printf("Redeclaracion de variable!!!\n");
			exit(1);
		}
		checkTypes($1 -> type, $4 -> type);
		$$ -> type = $1 -> type;
		assignUnary($2,$4, '=');
		assignUnary($$, $2, '=');
		putsym($2 -> name, $1 -> type);
		symrec* aux = getsym($2 -> name);
		assignUnary(aux, $4, '=');
	}
	| type variable '=' variable  { 
		symrec *aux;
		if((aux = getsym($4 -> name)) == NULL) {
			printf("La variable no ha sido declarada!!!\n");
			exit(1);
		}
		if(getsym($2 -> name) != NULL) {
			printf("La variable se redeclaro\n");
			exit(1);
		}
		checkTypes($1 -> type, aux -> type);
		assignUnary($2, aux, '=');
		assignUnary($$, aux, '=');
		$$ -> type = aux -> type;
		putsym($2 -> name, aux -> type);
		printf("tipo idenfificador = idenfificador\n"); 
	}
	| type variable  { 
		if(getsym($2 -> name) != NULL) {
			printf("La variable se redeclaro\n");
			exit(1);
		}
		$$ -> type = $1 -> type;
		putsym($2 -> name, $1 -> type);
		printf("tipo idenfificador\n"); 
	}
	| type variable '=' '{' const_list '}'    	{ printf("tipo idenfificador[entero] = {lista}\n"); }
	;
variable
	: IDENTIFIER'['expression']'  {printf("Identificador[expresion]\n");}
	| IDENTIFIER'['CONST_INT']'   {printf("Identificador[constante]\n");}
	| IDENTIFIER'['IDENTIFIER']'  {printf("Identificador[Identificador]\n");}
	| IDENTIFIER {
		printf("Identifier: %s\n", $1 -> name);
		strcpy($$ -> name, $1 -> name); 
		printf("Identificador<---\n");
	}
	;
while
	: WHILE '(' condition ')' '{' code_block '}'   { printf("while\n"); }
	;

for 
	: FOR '(' variable_declaration ';' condition ';' expression ')' '{' code_block '}'   { printf("for\n"); }
	;

if
	: IF '(' condition ')' '{' code_block '}'                       { printf("if\n"); }
	| IF '(' condition ')' '{' code_block '}' ELSE '{'code_block'}'  { printf("if else\n"); }
	;

expression
	: constant { 
		printf("constate: "); 
		if($$ == NULL || $1 == NULL) {
			printf("xd\n");
			exit(1);
		}
		$$ -> type = $1 -> type; 
			
	}
	| expression '+' expression  { 
		checkTypes($1-> type, $3 -> type);
		$$ -> type = $1 -> type;
		assignValue($$, $1, $3, '+');
		printf("expresion + expresion\n"); 
	}
	| expression '-' expression { 
		checkTypes($1-> type, $3 -> type);
		$$ -> type = $1 -> type;
		assignValue($$, $1, $3, '-');
          	printf("expresion - expresion\n"); 
    }
	| expression '*' expression { 
		checkTypes($1-> type, $3 -> type);
		$$ -> type = $1 -> type;
		assignValue($$, $1, $3, '*');
		printf("expression * expression\n");
    }
	| expression '/' expression { 
		checkTypes($1-> type, $3 -> type);
		$$ -> type = $1 -> type;
		assignValue($$, $1, $3, '/');
		printf("expression / expression\n"); 
    }
	| FUNCTION  '(' expression ')' { printf("funcion\n"); }
	| '-' expression %prec NEG     { printf("- expression\n"); }
	| '(' expression ')' { 
		$$ -> type = $2 -> type;
		printf("(expression)\n"); 
    }
	| variable PLUSPLUS { 
		$$ -> type = $1 -> type;
		assignUnary($$, $1, PLUSPLUS);
		printf("idenfificado++\n"); 
    }
	| variable MINUSMINUS { 
		$$ -> type = $1 -> type;
		assignUnary($$, $1, MINUSMINUS);
		printf("idenfificador--\n"); 
    }
	| variable JOIN CONST_CHAR variable { printf("Join completo"); }
	| variable                          { printf("idenfificador\n"); }
	| condition                         { printf("condicion\n"); }
	| variable '='expression { 
		checkTypes($1 -> type, $3 -> type);
		$$ -> type = $3 -> type;
		assignUnary($1, $3, '=');
		assignUnary($$, $1, '=');
		printf("idenfificador = expresion\n"); 
	}
	;
condition
	: condition logical_operator condition { 
		checkTypes($1 -> type, $3 -> type);
		assignValue($$, $1, $3, $2); 
		printf("condicion op condicion\n"); 
    }
	| variable { 
		if($1 -> type != _BOOL_){
			printf("No coinciden los tipos mi tio\n");
			exit(1);
		}
		$$ -> type = $1 -> type;
		$$ -> value._bool = $1 -> value._bool;
		printf("variable\n"); 
    }
	| constant { 
		if($1 -> type != _BOOL_) {
			printf("Solo se puede true o false padrino\n");
			exit(1);
		}
		$$ -> type = _BOOL_;
		$$ -> value._bool = $1 -> value._bool;
		printf("constante: ");
    }
	| '!' condition { 
        	if($2 -> type != _BOOL_) {
        		printf("No coinciden los tipos mi tio\n");
        		exit(1);
          	}
		$$ -> type = CONST_BOOL;
		assignUnary($$, $2, '!');
		printf("no condicion\n");
    }
	| '(' condition ')' { 
		$$ -> type = $2 -> type;
		assignUnary($$,$2,'=');
		printf("(condicion)\n"); 
    }
	;

logical_operator
	: LESS                    
	| GREATER
	| GREATER_EQ
	| LESS_EQ
	| AND_OP
	| NEQ
	| OR_OP
	;

const_list
	: constant ',' const_list  { printf("costante, lista\n"); }
	| constant                 { printf("constante: "); }
	;

constant
	: CONST_INT     { $$ -> type = _INT_; printf("const_int\n"); }
	| CONST_FLOAT   { $$ -> type = _FLOAT_; printf("const_float\n"); }
	| CONST_DOUBLE  { $$ -> type = _DOUBLE_; printf("const_double\n"); }
	| CONST_CHAR    { $$ -> type = _CHAR_; printf("const_char\n"); }
	| BOOL          { $$ -> type = _BOOL_; printf("const_bool\n"); }
	;

type
	: INT      { $$ -> type = _INT_; printf("int\n"); }
	| FLOAT    { $$ -> type = _FLOAT_; printf("float\n"); }
	| DOUBLE   { $$ -> type = _DOUBLE_; printf("double\n"); }
	| LONG     { $$ -> type = _LONG_; printf("long\n"); }
	| BOOL     { $$ -> type = _BOOL_; printf("bool\n"); }
	| CHAR     { $$ -> type = _CHAR_; printf("char\n"); }
	;


%%
tabla_hash sym_table;
void init_table() {
	int i = 0;
	sym_table.MOD = 9887;
	for(i = 0; i < sym_table.MOD; i++) {
		sym_table.table[i] = NULL;
	}
}
int get_hash(char const *name) {
	printf("gethash\n");
	int i = 0;
	int ret = 0;
	int pot = 1;
	int prime = 31;
	printf("Name: %s\n", name);
	for(i = 0; i < strlen(name); i++) {
		ret += (name[i]*pot)%sym_table.MOD;
		if(ret > sym_table.MOD)
			ret -= sym_table.MOD;
		pot = (pot * prime) % sym_table.MOD;
	}
	printf("Valor hash: %d\n", ret);
	return ret % sym_table.MOD;
}

void putsym(char const *name, int sym_type) {
	printf("putsym\n");
	int hash_val = get_hash(name);
	symrec *new_one = (symrec *) malloc (sizeof (symrec));
	strcpy(new_one -> name, name);
	new_one -> type = sym_type;
	sym_table.table[hash_val] = new_one;
}
symrec *getsym(char const *name) {
	printf("getsym\n");
	int hash_val = get_hash(name);
	return sym_table.table[hash_val];
}
int main(int argc, char** argv) {
	init_table();
	yyparse();
	return 0;
}

void assignUnary(symrec* $$, symrec* $1, int opc) {
    switch($1 -> type) {
      case _INT_:
        switch(opc) {
          case '-': $$ -> value._int = -$1 -> value._int; break;
          case '=': $$ -> value._int = $1 -> value._int; break;
          case PLUSPLUS: $$ -> value._int = $1 -> value._int + 1; break;
          case MINUSMINUS: $$ -> value._int = $1 -> value._int - 1; break;
        }
        break;
      case _FLOAT_:
        switch(opc) {
          case '-': $$ -> value._float = -$1 -> value._float; break;
          case '=': $$ -> value._float = $1 -> value._float; break;
          case PLUSPLUS: $$ -> value._float = $1 -> value._float + 1; break;
          case MINUSMINUS: $$ -> value._float = $1 -> value._float - 1; break;
        }
        break;
      case _DOUBLE_:
        switch(opc) {
          case '-': $$ -> value._double = -$1 -> value._double; break;
          case '=': $$ -> value._double = $1 -> value._double; break;
          case PLUSPLUS: $$ -> value._double = $1 -> value._double + 1; break;
          case MINUSMINUS: $$ -> value._double = $1 -> value._double - 1; break;
        }
        break;
      case _CHAR_:
        switch(opc) {
          case '=': $$ -> value._char = $1 -> value._char; break;
        }
        break;
      case _BOOL_:
        if(opc == '!') {
          $$ -> value._bool = !($1 -> value._bool); break;
        }
        else if(opc == '='){
          $$ -> value._bool = $1-> value._bool;
        }
        break;
      case _LONG_:
        switch(opc) {
          case '-': $$ -> value._long = -$1 -> value._long; break;
          case '=': $$ -> value._long = -$1 -> value._long; break;
          case PLUSPLUS: $$ -> value._long = $1 -> value._long + 1; break;
          case MINUSMINUS: $$ -> value._long = $1 -> value._long - 1; break;
        } 
        break;
      default:
        printf("Hay un error!\n");
        exit(1);
    }
  }
  // Para operaciones binarias
void assignValue(symrec* a, symrec* b, symrec* c, int opc) {
	switch(b -> type) {
		case _INT_:
			switch(opc) {
				case '+': a -> value._int = b -> value._int + c -> value._int; break;			
				case '-': a -> value._int = b -> value._int - c -> value._int; break;			
				case '*': a -> value._int = b -> value._int * c -> value._int; break;			
				case '/': a -> value._int = b -> value._int / c -> value._int; break;			
				case '<': a -> value._bool = b -> value._int < c -> value._int; break;			
				case '>': a -> value._bool = b -> value._int > c -> value._int; break;
				case GREATER_EQ: a -> value._bool = b -> value._int >= c -> value._int; break;
				case LESS_EQ: a -> value._bool = b -> value._int <= c -> value._int; break;
				case NEQ: a-> value._bool = b -> value._int != c -> value._int; break;
				default:
					printf("Te faltan manos men\n");
					exit(1);
			}
			break;
		case _FLOAT_:
			switch(opc) {
				case '+': a -> value._float = b -> value._float + c -> value._float; break;
				case '-': a -> value._float = b -> value._float - c -> value._float; break;
				case '*': a -> value._float = b -> value._float * c -> value._float; break;
				case '/': a -> value._float = b -> value._float / c -> value._float; break;
				case '<': a -> value._bool = b -> value._float < c -> value._float; break;
				case '>': a -> value._bool = b -> value._float > c -> value._float; break;
				case GREATER_EQ: a -> value._bool = b -> value._float >= c -> value._float; break;
				case LESS_EQ: a -> value._bool = b -> value._float <= c -> value._float; break;
				case NEQ: a-> value._bool = b -> value._float != c -> value._float; break;
				default:
					printf("Te faltan manos men\n");
					exit(1);
			}
			break;
		case _DOUBLE_:
			switch(opc) {
				case '+': a -> value._double = b -> value._double + c -> value._double; break;
				case '-': a -> value._double = b -> value._double - c -> value._double; break;
				case '*': a -> value._double = b -> value._double * c -> value._double; break;
				case '/': a -> value._double = b -> value._double / c -> value._double;break;
				case '<': a-> value._bool = b -> value._double < c -> value._double;break;
				case '>': a-> value._bool = b -> value._double > c -> value._double;break;
				case GREATER_EQ: a -> value._bool = b -> value._double >= c -> value._double;break;
				case LESS_EQ: a-> value._bool = b -> value._double <= c -> value._double;break;
				case NEQ: a-> value._bool = b -> value._double != c -> value._double; break;
				default:
					printf("Te faltan manos men\n");
					exit(1);
			}
			break;
		case _CHAR_:
			switch(opc) {
				case '+': a -> value._char = b -> value._char + c -> value._char; break;
				case '-': a -> value._char = b -> value._char - c -> value._char; break;
				case '*': a -> value._char = b -> value._char * c -> value._char; break;
				case '/': a -> value._char = b -> value._char / c -> value._char; break;
				default:
					printf("Te faltan manos men\n");
					exit(1);
			}
			break;
		case _BOOL_:
			switch(opc) {
				case '+': a -> value._bool = b -> value._bool | c -> value._bool; break;
				case '*': a -> value._bool = b -> value._bool & c -> value._bool; break;
				case OR_OP: a -> value._bool = b -> value._bool | c -> value._bool; break;
				case AND_OP: a -> value._bool = b -> value._bool & c -> value._bool; break;	
  				case NEQ: a-> value._bool = b -> value._bool != c -> value._bool; break;
				default:
					printf("Te faltan manos men\n");
					exit(1);
			}
			break;
		case _LONG_:
			switch(opc) {
				case '+': a -> value._long = b -> value._long + c -> value._long; break;	
				case '-': a -> value._long = b -> value._long - c -> value._long; break;	
				case '*': a -> value._long = b -> value._long * c -> value._long; break;	
				case '/': a -> value._long = b -> value._long / c -> value._long; break;	
				case '<': a-> value._bool = b -> value._long < c -> value._long; break;
				case '>': a-> value._bool = b -> value._long > c -> value._long; break;
				case GREATER_EQ: a -> value._bool = b -> value._long >= c -> value._long;break;
				case LESS_EQ: a-> value._bool = b -> value._long <= c -> value._long; break;
				case NEQ: a-> value._bool = b -> value._long != c -> value._long; break;
				default:
					printf("Te faltan manos men\n");
					exit(1);
			}
			break;
		default:
			printf("Hay un error!\n");
			exit(1);
	}
}

