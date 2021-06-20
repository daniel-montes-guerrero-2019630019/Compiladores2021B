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
	#define _TILE_ 8
	#define _SMARTTILE_ 9
	#define _SECTION_ 10
	#define _CONTAINER_ 11
	#define PERLIN_NOISE 20
	#define SMOOTHED_PERLIN_NOISE 21
	#define RANDOM_WALK 22
	#define SMOOTHED_RANDOM_WALK 23
	#define PERLIN_NOISE_CAVE 24
	#define RANDOM_WALK_CAVE 25
	#define DIRECCIONAL_TUNNEL 26
	#define CELLULAR_AUTOMATA 27 
	#define MOORE_CELLULAR_AUTOMATA 28
	#define VON_NEUMANN_CELLULAR_AUTOMATA 29

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
	void put_attribute(Section* a, symrec* attribute, symrec* constant);
	char* resize_string(char *code, int *new_len, int req_len);
  %}

%define api.value.type union
%token <symrec*> IDENTIFIER 
%token <symrec*> INT FLOAT DOUBLE LONG BOOL CHAR STRING
%token <symrec*> CONST_CHAR CONST_BOOL CONST_LONG
%token <symrec*> CONST_INT CONST_FLOAT CONST_DOUBLE CONST_STRING
%nterm <symrec*> variable_declaration variable type expression condition constant vector rule tile
%nterm <int> logical_operator comparation_operator
%nterm <TileList*> tiles_list
%nterm <Tile*> tile_content
%nterm <symrec*> smarttile
%nterm <Section*> section_declaration

%token FUNCTION
%token MAIN
%token <char*> ALGORITHM 
%token PLUSPLUS MINUSMINUS
%token FOR WHILE IF ELSE
%token <symrec*> RULE
%token <int> SMARTTILE
%token SET TILE SECTION
%token _BEGIN END NEW JOIN CONTAINER
%token NAME TILESET DEFAULT
%token <int> GREATER_EQ LESS_EQ AND_OP OR_OP NEQ GREATER LESS EQ

%precedence '='
%left '-' '+'
%left '*' '/'
%precedence NEG

%%
// declaracion inicial main
input
	: %empty
	| set_size initial_declaration main_function 		{
								}
	;
set_size
	: SET '=''{' CONST_INT','CONST_INT'}'';' 		{
								}
	;

initial_declaration
	: initial_declaration section			{
							}
	| initial_declaration smarttile			{
							}
	| smarttile					{
							} 
	| section					{
							}
	;
smarttile
	: SMARTTILE IDENTIFIER '{'tiles_list'}'		{
			symrec* aux = getsym($2->name);
			if(aux != NULL) {
				printf("No te chifles, mae. La ingenieria no es para los chiflados\n");
				exit(1);
			}
			$$ = (symrec*)malloc(sizeof(symrec)); 
			putsym($2 -> name, $1);
			$$ = getsym($2 -> name);
			$$ -> type = SMARTTILE;
			$$ -> value.smart_tile = (Smarttile*)malloc(sizeof(Smarttile));
			$$ -> value.smart_tile -> tiles = $4;
			char *code1 = pop(&pila_codigo);
			char *code = (char*)malloc(sizeof(char)*(strlen(code1) + 100 + 3*strlen($2 -> name)));
			sprintf(
				code, 
				"List<Rule> %s = new List<Rule>(){%s};\nCreateRuleTile(\"%s\",%s);", 
				$2 -> name, 
				code1, 
				$2 -> name,
				$2 -> name
			);
			push(&pila_codigo, code);
							}
	;
tiles_list
	: tile tiles_list				{
			$$ = (TileList*) malloc(sizeof(TileList));
			$$ -> data = $1 -> value.tile;
			$$ -> next = $2;
			char *code2 = pop(&pila_codigo);
			char *code1 = pop(&pila_codigo);
			char* code = (char*)malloc(sizeof(char)*(strlen(code1)+strlen(code2)+20));
			sprintf(code,"%s, %s", code1, code2);
			push(&pila_codigo, code);
							}
	| tile 						{ 
			$$ = (TileList*) malloc(sizeof(TileList));
			$$ -> data = $1 -> value.tile;
			$$ -> next = NULL;
			char* code1 = pop(&pila_codigo);
			char* code = (char*)malloc(sizeof(char)*(strlen(code1)+20));
			sprintf(code, "%s", code1);
			push(&pila_codigo, code);
							}
	;

tile
	: TILE IDENTIFIER '{'tile_content rule'}'	{
			int isMultipleSprite = strlen($4 -> tileset);
			if(getsym($2 -> name) != NULL) {
				printf("60 anios, una protesis\n");
				exit(1);
			}
			putsym($2 -> name, _TILE_);
			symrec *aux = getsym($2 -> name);
			aux -> value.tile = $4;
			
			if($5 != NULL) {
				for(int i = 0; i < 3; i++) {
					for(int j = 0; j < 3; j++) {
						aux -> value.tile -> rule[i][j] = $5 -> value.tile -> rule[i][j];
					}
				}
			}
			aux -> value.tile -> id = (char*)malloc(sizeof(char)*strlen($2 -> name));
			strcpy(aux -> value.tile -> id, $2 -> name);
			$$ = aux;
			char *code2 = pop(&pila_codigo);
			char *code1 = pop(&pila_codigo);
			char *code = (char*)malloc(sizeof(char)*(strlen(code1)+strlen(code2) + 100));
			if($5 != NULL) {
				sprintf(
					code,
					"new Rule{%s matrixOfNeighbors=new int[,] %s",
					code1,
					code2
					);
			}
			else {
				sprintf(
					code,
					"new Rule{%s matrixOfNeighbors=new int[,] {}",
					code1
					);
			}
			push(&pila_codigo, code);
							}
	;

section
	: SECTION IDENTIFIER ':' ALGORITHM '{'section_declaration'}'  	{
			if(getsym($2 -> name) != NULL) {
				printf("Escuchame pequenio cuck. Mis gustos son God y los tuyos zzzz. Yo soy basado y tu das cringe. Yo soy un chad y tu un virgen, y no puedes hacer nada para cambiarlo\n");
				exit(1);
			}
			putsym($2 -> name, _SECTION_);
			symrec* aux = getsym($2 -> name);
			aux -> type = _SECTION_;
			aux -> value.algo = $6;
			aux -> value.algo -> algorithm = (char*)malloc(sizeof(char)*(strlen($4)));
			strcpy(aux -> value.algo -> algorithm, $4);

			char *code1 = pop(&pila_codigo);
			char *code = (char*)malloc(sizeof(char)*(strlen(code1)+strlen($4)+strlen($2 -> name)+100));
			sprintf(code, "templates[\"%s\"] = new Template {%s algorithm = \"%s\"};", $2 -> name,code1, $4);
			push(&pila_codigo, code);
									}
	;

section_declaration
	:  section_declaration IDENTIFIER'='constant';' 		{ 
		$$ = $1;
		put_attribute($$,$2,$4);
		char *code2 = pop(&pila_codigo);
		char *code1 = pop(&pila_codigo);
		char *code = malloc(sizeof(char)*(strlen($2 -> name) + strlen(code2) + 100 + strlen(code1)));
		sprintf(code, "%s %s = %s,", code1, $2 -> name, code2);
		push(&pila_codigo, code);

									}
	| IDENTIFIER'='constant';'					{
		$$ = (Section*)malloc(sizeof(Section));
		char *code1 = pop(&pila_codigo);
		char *code = malloc(sizeof(char)*(strlen($1 -> name) + strlen(code1) + 100));
		sprintf(code, "%s = %s,", $1 -> name, code1);
		push(&pila_codigo, code);
									}
	;
tile_content
	: NAME '=' CONST_STRING ';' TILESET'='CONST_STRING ';' DEFAULT'=' CONST_BOOL';' {
			printf("tile_content");
			$$ = (Tile*)malloc(sizeof(Tile));
			$$ -> name = (char*) malloc(sizeof(char)*strlen($3 -> value._string));
			strcpy($$ -> name, $3 -> value._string);
			$$ -> tileset = (char*) malloc(sizeof(char)*strlen($7 -> value._string));
			strcpy($$ -> tileset, $7 -> value._string);
			$$ -> flag = $11 -> value._bool;			

			char *code = (char*)malloc(sizeof(char)*(strlen($$ -> name) + strlen($$ -> tileset) + 1000));
			sprintf(code,
				"spritePath=\"%s\", spriteMultiplePath=\"%s\",isDefault=%s,isMultipleSprite=%s,",
					$$ -> name,
					$$ -> tileset,
					($$ -> flag? "true" : "false"),
					(strlen($$->tileset)? "true":"false")
				);
			push(&pila_codigo, code);
											}
	;

main_function
	: MAIN '{' code_block '}'  { }
	;

code_block
	: statement ';'             { /*printf("statement");*/ }
	| statement ';' code_block   { /*printf("statement code_block");*/ }
	| error                  { yyerrok; }
	;
rule
	: %empty		{ $$ = NULL; }
	| RULE '=''{'vector','vector','vector'}'	{
			$$ = (symrec*)malloc(sizeof(symrec));	
			$$ -> value.tile = (Tile*)malloc(sizeof(Tile));
			for(int i = 0; i < 3; i++)
				$$ -> value.tile -> rule[0][i]= $4 -> value._vector[i];
			for(int i = 0; i < 3; i++)
				$$ -> value.tile -> rule[1][i]= $6 -> value._vector[i];
			for(int i = 0; i < 3; i++)
				$$ -> value.tile -> rule[2][i]= $8 -> value._vector[i];
			char *code3 = pop(&pila_codigo);
			char *code2 = pop(&pila_codigo);
			char *code1 = pop(&pila_codigo);
			char *code = (char*)malloc(sizeof(char)*(strlen(code1) + strlen(code2) + strlen(code3) + 10));
			sprintf(code, "{%s,%s,%s}", code1, code2, code3);
			push(&pila_codigo, code);

							}
	;
vector
	: '{'expression','expression','expression'}' 	{
			checkTypes($2 -> type, $4 -> type);
			checkTypes($4 -> type, $6 -> type);
			if($2 -> type != _INT_)  {
				printf("Hoy es noche de FREE FIRE!!!\n");
			}
			$$ = (symrec*)malloc(sizeof(symrec));
			$$ -> value._vector[0] = $2 -> value._int;
			$$ -> value._vector[1] = $4 -> value._int; 
			$$ -> value._vector[2] = $6 -> value._int;
			char *code3 = pop(&pila_codigo);
			char *code2 = pop(&pila_codigo);
			char *code1 = pop(&pila_codigo);
			char *code = (char*)malloc(sizeof(char)*(strlen(code1) + strlen(code2) + strlen(code3) + 10));
			sprintf(code, "{%s,%s,%s}", code1, code2, code3);
			push(&pila_codigo, code);
							}
	;
statement
	: variable_declaration   	{ /*printf("variable\n");*/ }
	| expression   			{ /*printf("expresion\n");*/}
	| for          			{ /*printf("for\n");*/ }
	| while        			{ /*printf("while\n");*/ }
	| if           			{ /*printf("if\n");*/ }
	;
variable_declaration
	: type variable '=' expression             	{
		if(getsym($2 -> name) != NULL) {
			printf("Redeclaracion de variable!!!\n");
			exit(1);
		}
		checkTypes($1 -> type, $4 -> type);
		$$ -> type = $1 -> type;
		assignUnary($2, $4, '=');
		$2 -> type = $1 -> type;
		assignUnary($$, $2, '=');
		putsym($2 -> name, $1 -> type);
		symrec* aux = getsym($2 -> name);
		assignUnary(aux, $4, '=');
							}
	| type variable '=' variable                	{ 
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
							}
	| type variable   		                { 
		if(getsym($2 -> name) != NULL) {
			printf("La variable se redeclaro\n");
			exit(1);
		}
		$$ -> type = $1 -> type;
		putsym($2 -> name, $1 -> type);
		// printf("tipo idenfificador\n"); 
							}
	| CONTAINER IDENTIFIER '['CONST_INT']' 		{
		if(getsym($2 -> name) != NULL) {
			printf("yabasayorar?\n");
			exit(1);
		}
		char** array = (char**)malloc(sizeof(char*)*$4 -> value._int);
		putsym($2 -> name, _SECTION_);
		symrec* aux = getsym($2 -> name);
		$2 -> value.array = array;
		aux -> type = _SECTION_;
		$$ = aux;
							}
	;
variable
	: IDENTIFIER'['expression']'			{
		$$ = getsym($1 -> name);
		if($$ == NULL) {
			printf("Su pata del mameitor\n");
			exit(1);
		}
		checkTypes(_INT_, $3 -> type);
		$$ = (symrec*)malloc(sizeof(symrec));
		strcpy($$ -> name, $1 -> name); 
		$$ -> value._int = $3 -> value._int;

		char *code2 = pop(&pila_codigo);
		char *code1 = pop(&pila_codigo);
		char *code = (char*)malloc(sizeof(char)*(strlen(code1) + strlen(code2) + 4));
		strcpy(code, code1);
		strcat(code, "[");
		strcpy(code, code2);
		strcat(code, "]");
							}
	| IDENTIFIER					{
		strcpy($$ -> name, $1 -> name); 
		char *code = (char*)malloc(sizeof($1 -> name));
		strcpy(code, $1 -> name);
		push(&pila_codigo, code);
							}
	;
while
	: WHILE '(' condition ')' '{' code_block '}'   { /*printf("while\n");*/ }
	;

for 
	: FOR '(' variable_declaration ';' condition ';' expression ')' '{' code_block '}'   { /*printf("for\n");*/ }
	;

if
	: IF '(' condition ')' '{' code_block '}'   				{ /*printf("if\n");*/ }
	| IF '(' condition ')' '{' code_block '}' ELSE '{'code_block'}'  	{ /*printf("if else\n");*/ }
	;

expression
	: constant                       		{ 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> type = $1 -> type; 
		assignUnary($$, $1, '=');			
							}
	| expression '+' expression      		{ 
		$$ = (symrec*)malloc(sizeof(symrec));
		checkTypes($1 -> type, $3 -> type);
		$$ -> type = $1 -> type;
		assignValue($$, $1, $3, '+');
		// printf("expresion + expresion\n"); 
		char *code2 = pop(&pila_codigo);
		char *code1 = pop(&pila_codigo);
		char *code = (char*)malloc(sizeof(char)*(strlen(code1) + strlen(code2) + 4));
		strcpy(code, code1);
		strcat(code, "+");
		strcat(code, code2);
		push(&pila_codigo, code);

		
							}
	| expression '-' expression      		{ 
		$$ = (symrec*)malloc(sizeof(symrec));
		checkTypes($1-> type, $3 -> type);
		$$ -> type = $1 -> type;
		assignValue($$, $1, $3, '-');

		char *code2 = pop(&pila_codigo);
		char *code1 = pop(&pila_codigo);
		char *code = (char*)malloc(sizeof(char)*(strlen(code1) + strlen(code2) + 4));
		strcpy(code, code1);
		strcat(code, "-");
		strcat(code, code2);
		push(&pila_codigo, code);

          	// printf("expresion - expresion\n"); 
              						}
	| expression '*' expression      		{ 
		$$ = (symrec*)malloc(sizeof(symrec));
		checkTypes($1-> type, $3 -> type);
		$$ -> type = $1 -> type;
		assignValue($$, $1, $3, '*');

		char *code2 = pop(&pila_codigo);
		char *code1 = pop(&pila_codigo);
		char *code = (char*)malloc(sizeof(char)*(strlen(code1) + strlen(code2) + 4));
		strcpy(code, code1);
		strcat(code, "*");
		strcat(code, code2);
		push(&pila_codigo, code);

		free($1);
		free($3);
              						}
	| expression '/' expression      		{ 
		$$ = (symrec*)malloc(sizeof(symrec));
		checkTypes($1-> type, $3 -> type);
		$$ -> type = $1 -> type;
		assignValue($$, $1, $3, '/');
		
		char *code2 = pop(&pila_codigo);
		char *code1 = pop(&pila_codigo);
		char *code = (char*)malloc(sizeof(char)*(strlen(code1) + strlen(code2) + 4));
		strcpy(code, code1);
		strcat(code, "/");
		strcat(code, code2);
		push(&pila_codigo, code);

		free($1);
		free($3);
              						}
	| '-' expression %prec NEG       		{ 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> type = $2 -> type;
		assignUnary($$, $2, '-');
		char *code1 = pop(&pila_codigo);
		char *code = (char*)malloc(sizeof(char)*(strlen(code1) + 4));
		code[0] = '-'; code[1] = '\0';
		strcat(code, code1);
		push(&pila_codigo, code);

		free($2);
							}
	| '(' expression ')'             		{ 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> type = $2 -> type;
		assignUnary($$, $2, '=');

		char *code1 = pop(&pila_codigo);
		char *code = (char*)malloc(sizeof(char)*(strlen(code1) + 4));
		code[0] = '('; code[1] = '\0';
		strcat(code, code1);
		strcat(code, ")");
		push(&pila_codigo, code);

		free($2);
              						}
	| variable PLUSPLUS                    		{ 
		$$ = (symrec*)malloc(sizeof(symrec));
		symrec* aux = getsym($1 -> name);
		if(aux == NULL) {
			printf("Ni vas a acabar la carrera\n");
			exit(1);
		}
		$$ -> type = aux -> type;
		assignUnary(aux, aux, PLUSPLUS);
		assignUnary($$, aux, '=');

		char *code1 = pop(&pila_codigo);
		char *code = (char*)malloc(sizeof(char)*(strlen(code1)+5));
		strcpy(code, code1);
		strcat(code, "++");
		push(&pila_codigo, code);

		free($1);
              						}
	| variable MINUSMINUS                    	{ 
		$$ = (symrec*)malloc(sizeof(symrec));
		symrec* aux = getsym($1 -> name);
		if(aux == NULL) {
			printf("te pido el cambio de carrera o tu lo pides?");
			exit(1);
		}
		$$ -> type = aux -> type;
		assignUnary(aux, aux, MINUSMINUS);
		assignUnary($$, aux, '=');

		char *code1 = pop(&pila_codigo);
		char *code = (char*)malloc(sizeof(char)*(strlen(code1)+5));
		strcpy(code, code1);
		strcat(code, "--");
		push(&pila_codigo, code);

		free($1);
              						}
	| variable                     			{ 
		symrec* aux = getsym($1 -> name);
		if(aux == NULL) {
			printf("Se esta usando una variable no declarada\n");
			exit(1);
		}
		$$ -> type = aux -> type;
		assignUnary($$, aux, '=');
		free($1);
							}
	| condition                      		{ 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> type = _BOOL_;
		$$ -> value._bool = $1 -> value._bool;
		int actLen = strlen(pila_codigo -> code);

							}
	| variable '=' expression      			{ 
		symrec* aux = getsym($1 -> name);
		if(aux == NULL) {
			printf("Neta we, ya mejor vete a dormir\n");
			exit(1);
		}
		checkTypes(aux -> type, $3 -> type);
		$$ -> type = $3 -> type;
		assignUnary(aux, $3, '=');
		assignUnary($$, aux, '=');

		char *code2 = pop(&pila_codigo);
		char *code1 = pop(&pila_codigo);
		char *code = (char*)malloc(sizeof(char)*(strlen(code1) + strlen(code2) + 10));
		strcpy(code, code1);
		strcat(code, "=");
		strcat(code, code2);
		push(&pila_codigo, code);

		free($3);
		free($1);
					      		}
	;
//| variable JOIN CONST_CHAR variable		{ printf("Join completo"); }
// 1 <-
condition
	: condition logical_operator condition  	    	{ 
		$$ = (symrec*)malloc(sizeof(symrec));
		checkTypes($1 -> type, $3 -> type);
		assignValue($$, $1, $3, $2); 
		char *code3 = pop(&pila_codigo);
		char *code2 = pop(&pila_codigo);
		char *code1 = pop(&pila_codigo);
		char *code = (char*)malloc(sizeof(char)*(strlen(code1) + strlen(code2) + strlen(code3) + 10));
		strcpy(code, code1);
		strcat(code, code2);
		strcat(code, code3);
		push(&pila_codigo, code);

              						    	}
	| expression comparation_operator expression        	{ 
		$$ = (symrec*)malloc(sizeof(symrec));
		checkTypes($1 -> type, $3 -> type);
		$$ -> type = _BOOL_;
		assignValue($$, $1, $3, $2);
		char *code3 = pop(&pila_codigo);
		char *code2 = pop(&pila_codigo);
		char *code1 = pop(&pila_codigo);
		char *code = (char*)malloc(sizeof(char)*(strlen(code1) + strlen(code2) + strlen(code3) + 10));
		strcpy(code, code1);
		strcat(code, code2);
		strcat(code, code3);
		push(&pila_codigo, code);
		free($1);
		free($3);
              							}
	| CONST_BOOL                              		{ 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> type = _BOOL_;
		$$ -> value._bool = $1 -> value._bool;
		free($1);
		char code[10];
		if($$ -> value._bool) {
			strcpy(code, "true");
		}
		else{
			strcpy(code, "false");
		}
		push(&pila_codigo, code);
              							}
	| '!' condition                        			{ 
		$$ = (symrec*)malloc(sizeof(symrec));
        	if($2 -> type != _BOOL_) {
        		printf("No coinciden los tipos mi tio\n");
        		exit(1);
          	}
		$$ -> type = CONST_BOOL;
		assignUnary($$, $2, '!');
		char *code = (char*)malloc(sizeof(char)*(strlen(pila_codigo -> code) + 10));
		code[0] = '!'; code[1] = '\0';
		strcat(code, pila_codigo -> code);
		pop(&pila_codigo);
		push(&pila_codigo, code);

		// printf("no condicion\n");
              }
	| '!' variable 						{
		symrec *aux = getsym($2 -> name);
		if(aux == NULL || aux -> type != _BOOL_) {
			printf("No nos interesa tu rollo, nomas que funcione\n");
			exit(1);
		}
		$$ -> value._bool = !(aux -> value._bool);
		$$ -> type = _BOOL_;
		char *code = (char*)malloc(sizeof(char)*(strlen(pila_codigo -> code) + 10));
		code[0] = '!'; code[1] = '\0';
		strcat(code, pila_codigo -> code);
		push(&pila_codigo, code);
		pop(&pila_codigo);
		free($2);
								}
	| '(' condition ')'                     		{ 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> type = $2 -> type;
		char *code = (char*)malloc(sizeof(char)*(strlen(pila_codigo -> code) + 10));
		code[0] = '('; code[1] = '\0';
		strcat(code, pila_codigo -> code);
		strcat(code, ")");
		pop(&pila_codigo);
		push(&pila_codigo, code);
              							}
	;

logical_operator
	: AND_OP 					{ 
					$$ = $1; 
					char code[4] = "&&";
					push(&pila_codigo,  code);
							}
	| OR_OP						{ 
					$$ = $1; 
					char code[4] = "||";
					push(&pila_codigo, code);
							}
	;
comparation_operator
	: GREATER_EQ 					{ 
					$$ = $1; 	
					char code[4] = ">=";
					push(&pila_codigo, code);
							}
	| GREATER					{ 
					$$ = $1;
					char code[4] = ">";
					push(&pila_codigo, code);
							}
	| LESS_EQ					{ 
					$$ = $1; 
					char code[4] = "<=";
					push(&pila_codigo, code);
							}
	| LESS						{ 
					$$ = $1; 	
					char code[4] = "<";
					push(&pila_codigo, code);
							}
	| NEQ						{ 
					$$ = $1; 	
					char code[4] = "<";
					push(&pila_codigo, code);
							}
	| EQ						{ 
					$$ = $1; 
					char code[4] = "==";
					push(&pila_codigo, code);
							}
	;
constant
	: CONST_INT     { 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> value._int = $1 -> value._int; 
		$$ -> type = _INT_; 
		char code[25];
		sprintf(code, "%d", $$ -> value._int);
		push(&pila_codigo, code);
		}
	| CONST_FLOAT   { 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> value._float = $1 -> value._float; 
		$$ -> type = _FLOAT_; 
		char code[25];
		sprintf(code, "%f", $$ -> value._float);
		push(&pila_codigo, code);
		}
	| CONST_DOUBLE  { 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> value._double = $1 -> value._double; 
		$$ -> type = _DOUBLE_; 
		char code[25];
		sprintf(code, "%f", $$ -> value._double);
		push(&pila_codigo, code);
		printf("const_double\n"); 
		}
	| CONST_CHAR    { 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> value._char = $1 -> value._char; 
		$$ -> type = _CHAR_; 
		// printf("const_char\n"); 
		char code[10];
		sprintf(code, "'%c'", $$ -> value._char);
		push(&pila_codigo, code);
		}
	| CONST_BOOL   	{ 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> value._bool = $1 -> value._bool; 
		$$ -> type = _BOOL_; 
		char code[10];
		sprintf(code, "%s", ($$ -> value._bool? "true" : "false"));
		push(&pila_codigo, code);
		// printf("const_bool\n"); 
		}
	| CONST_STRING {
		$$ = (symrec*)malloc(sizeof(symrec));	
		int len = strlen($1 -> value._string);
		$$ -> value._string = (char*)malloc(sizeof(char)*len);
		strcpy($$ -> value._string, $1 -> value._string);
		$$ -> type = _STRING_;
		char* code = (char*)malloc(sizeof(char)*(strlen($1 -> value._string) + 4));
		code[0] = '\"';
		code[1] = '\0';
		code = strcat(code, $1 -> value._string);
		code = strcat(code, $1 -> value._string);
		code = strcat(code, "\"");
		push(&pila_codigo, code);
		free($1);
		}
	;

type
	: INT      { 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> type = _INT_; 
		char code[7];
		sprintf(code, "int");
		push(&pila_codigo, code);
		}
	| FLOAT    { 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> type = _FLOAT_; 
		char code[7];
		sprintf(code, "float");
		push(&pila_codigo, code);
		}
	| DOUBLE   { 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> type = _DOUBLE_; 
		char code[7];
		sprintf(code, "double");
		push(&pila_codigo, code);
		}
	| LONG     { 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> type = _LONG_; 
		char code[7];
		sprintf(code, "long");
		push(&pila_codigo, code);
		// printf("long\n"); 
		}
	| BOOL     { 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> type = _BOOL_; 
		char code[7];
		sprintf(code, "bool");
		push(&pila_codigo, code);
		// printf("bool\n"); 
		}
	| CHAR     { 
		$$ = (symrec*)malloc(sizeof(symrec));
		$$ -> type = _CHAR_; 
		char code[7];
		sprintf(code, "char");
		push(&pila_codigo, code);
		// printf("char\n"); 
		}
	| STRING   {
		$$  = (symrec*) malloc(sizeof(symrec));
		$$ -> type = _STRING_; 
		char code[7];
		sprintf(code, "string");
		push(&pila_codigo, code);
		// printf("String\n");
		}
	;


%%
tabla_hash sym_table;
Pila *pila_codigo;
void init() {
	int i = 0;
	sym_table.MOD = 9887;
	for(i = 0; i < sym_table.MOD; i++) {
		sym_table.table[i] = NULL;
	}
	pila_codigo = NULL;
}
int get_hash(char const *name) {
	int i = 0;
	int ret = 0;
	int pot = 1;
	int prime = 31;
	// printf("Name: %s\n", name);
	for(i = 0; i < strlen(name); i++) {
		ret += (name[i]*pot)%sym_table.MOD;
		if(ret > sym_table.MOD)
			ret -= sym_table.MOD;
		pot = (pot * prime) % sym_table.MOD;
	}
	// printf("Valor hash: %d\n", ret);
	return ret % sym_table.MOD;
}

void putsym(char const *name, int sym_type) {
	int hash_val = get_hash(name);
	symrec *new_one = (symrec *) malloc (sizeof (symrec));
	strcpy(new_one -> name, name);
	new_one -> type = sym_type;
	sym_table.table[hash_val] = new_one;
}
symrec *getsym(char const *name) {
	int hash_val = get_hash(name);
	return sym_table.table[hash_val];
}
char *pop(Pila **p) {
	if((*p) == NULL) {
		printf("Error, la pila esta vacia\n");
		exit(1);
	}
	Pila* aux = (*p);
	char *code = (char*)malloc(sizeof(char)*(strlen((*p) -> code) + 4));
	strcpy(code, (*p) -> code);
	(*p) = (*p) -> next;
	free(aux);
	return code;
}
void push(Pila **p, char* code) {
	printf("Mete: %s\n", code);
	Pila *aux = (Pila*)malloc(sizeof(Pila));
	aux -> next = (*p);
	aux -> code = (char*)malloc(sizeof(char)*(strlen(code) + 4));
	strcpy(aux -> code, code);
	(*p) = aux;
}
int main(int argc, char** argv) {
	init();
	yyparse();
	return 0;
}

void assignUnary(symrec* $$, symrec* $1, int opc) {
 	// printf("$1 -> type = %d\n", $1 -> type);
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
	case _STRING_:
		if(opc == '=') {
			int len = strlen($1 -> value._string);
			$$ -> value._string = (char*)malloc(len*sizeof(char));
			strcpy($$ -> value._string, $1 -> value._string);
		}
		else {
			printf("Que haces, eso no se puede\n");
		}
	break;
	case _SECTION_:
		if(opc == '=') {
			// $$ -> value._int -> al que quieres accesar
			$$ -> value.array[$$ -> value._int] = (char*)malloc(sizeof(char)*strlen($1 -> name));
			strcpy($$ -> value.array[$$ -> value._int], $1 -> name);
		}
		else {
			printf("RTFM\n");
			exit(1);
		}
      default:
      	printf("Error unario\n");
        printf("Hay un error!\n");
        exit(1);
    }
  }
  // Para operaciones binarias
void assignValue(symrec* a, symrec* b, symrec* c, int opc) {
	// printf("OPC: %d\n", opc);
	switch(b -> type) {
		case _INT_:
			// printf("B: %d\n", b -> value._int);
			// printf("C: %d\n", c -> value._int);
			switch(opc) {
				case '+': a -> value._int = b -> value._int + c -> value._int; break;			
				case '-': a -> value._int = b -> value._int - c -> value._int; break;			
				case '*': a -> value._int = b -> value._int * c -> value._int; break;			
				case '/': a -> value._int = b -> value._int / c -> value._int; break;			
				case LESS: a -> value._bool = b -> value._int < c -> value._int; break;			
				case GREATER: a -> value._bool = b -> value._int > c -> value._int; break;
				case GREATER_EQ: a -> value._bool = b -> value._int >= c -> value._int; break;
				case LESS_EQ: a -> value._bool = b -> value._int <= c -> value._int; break;
				case NEQ: a-> value._bool = b -> value._int != c -> value._int; break;
				case EQ: a-> value._bool = b -> value._int == c -> value._int; break;
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
				case LESS: a -> value._bool = b -> value._float < c -> value._float; break;
				case GREATER: a -> value._bool = b -> value._float > c -> value._float; break;
				case GREATER_EQ: a -> value._bool = b -> value._float >= c -> value._float; break;
				case LESS_EQ: a -> value._bool = b -> value._float <= c -> value._float; break;
				case NEQ: a-> value._bool = b -> value._float != c -> value._float; break;
				case EQ: a-> value._bool = b -> value._float == c -> value._float; break;
				default:
					printf("Te faltan manos men\n");
					exit(1);
			}
			break;
		case _DOUBLE_:
			// printf("%f / %f\n", b -> value._double, c -> value._double);
			switch(opc) {
				case '+': a -> value._double = b -> value._double + c -> value._double; break;
				case '-': a -> value._double = b -> value._double - c -> value._double; break;
				case '*': a -> value._double = b -> value._double * c -> value._double; break;
				case '/': a -> value._double = b -> value._double / c -> value._double;break;
				case LESS: a-> value._bool = b -> value._double < c -> value._double;break;
				case GREATER: a-> value._bool = b -> value._double > c -> value._double;break;
				case GREATER_EQ: a -> value._bool = b -> value._double >= c -> value._double;break;
				case LESS_EQ: a-> value._bool = b -> value._double <= c -> value._double;break;
				case NEQ: a-> value._bool = b -> value._double != c -> value._double; break;
				case EQ: a-> value._bool = b -> value._double == c -> value._double; break;
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
  				case EQ: a-> value._bool = b -> value._bool != c -> value._bool; break;
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
				case LESS: a-> value._bool = b -> value._long < c -> value._long; break;
				case GREATER: a-> value._bool = b -> value._long > c -> value._long; break;
				case GREATER_EQ: a -> value._bool = b -> value._long >= c -> value._long;break;
				case LESS_EQ: a-> value._bool = b -> value._long <= c -> value._long; break;
				case NEQ: a-> value._bool = b -> value._long != c -> value._long; break;
				case EQ: a-> value._bool = b -> value._long == c -> value._long; break;
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

void put_attribute(Section* a, symrec* attribute, symrec* constant) {
	if(strcmp(attribute -> name, "interval") == 0){
		checkTypes(_INT_, constant -> type);
		a -> _ints[0] = constant -> value._int;
	}
	else if(strcmp(attribute -> name, "minSectionWidth") == 0) {
		checkTypes(_INT_, constant -> type);
		a -> _ints[1] = constant -> value._int;
	}
	else if(strcmp(attribute -> name, "requiredFloor") == 0) {
		checkTypes(_INT_, constant -> type);
		a -> _ints[2] = constant -> value._int;
	}
	else if(strcmp(attribute -> name, "minPathWidth") == 0) {
		checkTypes(_INT_, constant -> type);
		a -> _ints[3] = constant -> value._int;
	}
	else if(strcmp(attribute -> name, "roughness") == 0) {
		checkTypes(_INT_, constant -> type);
		a -> _ints[4] = constant -> value._int;
	}
	else if(strcmp(attribute -> name, "curviness") == 0) {
		checkTypes(_INT_, constant -> type);
		a -> _ints[5] = constant -> value._int;
	}
	else if(strcmp(attribute -> name, "height") == 0) {
		checkTypes(_INT_, constant -> type);
		a -> _ints[6] = constant -> value._int;
	}
	else if(strcmp(attribute -> name, "fillPercent") == 0) {
		checkTypes(_INT_, constant -> type);
		a -> _ints[7] = constant -> value._int;
	}
	else if(strcmp(attribute -> name, "smoothCount") == 0) {
		checkTypes(_INT_, constant -> type);
		a -> _ints[8] = constant -> value._int;
	}
	else if(strcmp(attribute -> name, "x") == 0) {
		checkTypes(_INT_, constant -> type);
		a -> _ints[9] = constant -> value._int;
	}
	else if(strcmp(attribute -> name, "y") == 0) {
		checkTypes(_INT_, constant -> type);
		a -> _ints[10] = constant -> value._int;
	}
	else if(strcmp(attribute -> name, "edge") == 0) {
		checkTypes(_INT_, constant -> type);
		a -> _ints[11] = constant -> value._int;
	}
	else if(strcmp(attribute -> name, "maxPathWidth") == 0) {
		checkTypes(_INT_, constant -> type);
		a -> _ints[12] = constant -> value._int;
	}
	else if(strcmp(attribute -> name, "seed") == 0) {
		checkTypes(_DOUBLE_, constant -> type);
		a -> _floats[0] = constant -> value._double;
	}
	else if(strcmp(attribute -> name, "modifier") == 0) {
		checkTypes(_DOUBLE_, constant -> type);
		a -> _floats[1] = constant -> value._int;
	}
	else if(strcmp(attribute -> name, "fillerTile") == 0) {
		checkTypes(_STRING_, constant -> type);
		symrec *aux = getsym(constant -> value._string);
		if(aux == NULL) {
			printf("seguro?\n");
			exit(1);
		}
		a -> filler = aux -> value.smart_tile;
	}
	else {
		printf("It's called hentai and is art\n");
		exit(1);
	}
}
char* resize_string(char *code, int *new_len, int req_len) {
	while((*new_len) <= req_len) {
		(*new_len)*=2;
		code = (char*)realloc((void*)code, *new_len);
		if(code == NULL) {
			printf("Error\n");
			exit(1);
		}
	}
	return code;
}
