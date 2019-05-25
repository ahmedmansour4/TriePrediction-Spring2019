// Sean Szumlanski
// COP 3502, Spring 2019
//
// tries.c
// =======
// This file includes a functions for building a trie form a corpus and
// printing all the strings in a trie.


#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_WORD_LENGTH 1023

typedef struct TrieNode
{
	// Count how many times each string has been inserted into the trie. (An
	// alternative would be to have a flag variable that is either 0 or 1 to
	// simply indicate whether a string has been inserted or not.)
	int count;

	// Array of 26 TrieNode pointers. (This is not the same as a pointer to an
	// array of 26 TrieNodes, as the TrieNodes don't exist yet.)
	struct TrieNode *children[26];
} TrieNode;


// Recursive helper function for printTrie(). buffer is the string that it has
// been building up through each recursive call, and k is the next index where
// we will write a character (which is also the number of characters we have
// added to the string so far).
//
// NOTE: Within the for-loop, we could check for a NULL pointer before making
// a recursive call, but I suspect any modern compiler will optimize this to the
// point where it doesn't matter. If you're curious about that, you could try
// coding up both versions and seeing whether it makes a difference when you
// insert a huge number of randomly generated strings.
void printTrieHelper(TrieNode *root, char *buffer, int k)
{
	int i;

	if (root == NULL)
		return;

	if (root->count > 0)
		printf("%s (%d)\n", buffer, root->count);

	// Ensure this string is properly terminated before potentially printing it.
	buffer[k + 1] = '\0';

	// Now take each path, one by one, to the child nodes of the current node.
	// This might lead us to a NULL pointer, in which case the base case will
	// cause us to return immediately from the next recursive call.
	for (i = 0; i < 26; i++)
	{
		buffer[k] = i + 'a';
		printTrieHelper(root->children[i], buffer, k + 1);
	}

	// Wipe out any characters written during this function call and ensure the
	// truncated string is properly terminated.
	buffer[k] = '\0';
}

// Print all the strings represented in the trie rooted at this node.
void printTrie(TrieNode *root)
{
	char buffer[MAX_WORD_LENGTH + 1];
	buffer[0] = '\0';

	printTrieHelper(root, buffer, 0);
}

// Basic TrieNode creation function.
TrieNode *createNode(void)
{
	// This could be written as a one-liner: return calloc(1, sizeof(TrieNode));

	int i;
	TrieNode *n = malloc(sizeof(TrieNode));

	n->count = 0;
	for (i = 0; i < 26; i++)
		n->children[i] = NULL;

	return n;
}

// Insert a string into a trie. This function returns the root of the trie.
TrieNode *insert(TrieNode *root, char *str)
{
	int i, index, len = strlen(str);
	TrieNode *wizard;

	if (root == NULL)
		root = createNode();

	// As I mentioned in class, the wizard starts at the root node and spells
	// out the string being inserted as he/she jumps from node to node. (The
	// wizard is acting as a temp pointer.)
	wizard = root;

	for (i = 0; i < len; i++)
	{
		// This is kind of gross. There are probably cleaner ways of dealing with
		// this than simply printing an error and returning NULL.
		if (!isalpha(str[i]))
		{
			fprintf(stderr, "Error: \"%s\" contains non-alpha characters and will not be inserted.\n", str);
			return NULL;
		}

		index = tolower(str[i]) - 'a';

		// Before the wizard can move forward to the next node, (s)he needs to
		// make sure that node actually exists. If not, create it!
		if (wizard->children[index] == NULL)
			wizard->children[index] = createNode();

		// Now the wizard is able to jump forward.
		wizard = wizard->children[index];
	}

	// When we break out of the for-loop, the wizard should be at the terminal
	// node that represents the string we're trying to insert.
	wizard->count++;
	return root;
}

// Open an input file and build a trie from its contents. Assumes the input file
// contains no punctuation.
TrieNode *buildTrie(char *filename)
{
	TrieNode *root = NULL;
	char buffer[MAX_WORD_LENGTH + 1];

	FILE *ifp;

	if ((ifp = fopen(filename, "r")) == NULL)
	{
		fprintf(stderr, "Failed to open \"%s\" in buildTrie().\n", filename);
		return NULL;
	}

	// Insert strings one-by-one into the trie.
	while (fscanf(ifp, "%s", buffer) != EOF)
		root = insert(root, buffer);

	fclose(ifp);
	return root;
}

int main(void)
{
	TrieNode *root = buildTrie("corpus.txt");
	printTrie(root);

	// Stretch goal: Write a function that recursively destroys your trie.

	return 0;
}
