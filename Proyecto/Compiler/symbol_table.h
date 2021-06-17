#ifndef __SYMBOL_TABLE__
#define __SYMBOL_TABLE__

#include <stdlib.h>
#include <string.h> 
#include <math.h>

#define MAXN 9887

typedef double (func_t) (double);

typedef struct algo {
	int tipo;
	float _floats[2];
	int _ints[5];
}Algorithm;

typedef struct tile {
	char *nombre;
	char *tileset;
	int rule[3][3];
	int flag;
}Tile;

typedef struct symrec {
	char *name; 
	int type;  
	union
	{
		int _int;
		double _double;
		char _char;
		char* string;
		long long int _long;
		float _float;
		int _bool;
		Algorithm algo;
		Tile tile;
	} value;
	struct symrec *next;
}symrec;

typedef struct tabla_hash {
	symrec *table[MAXN];
	int MOD;
}tabla_hash;

extern tabla_hash sym_table;

void putsym (char const *name, int sym_type);
symrec* getsym (char const *name);

#endif
