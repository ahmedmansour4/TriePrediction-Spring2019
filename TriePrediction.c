// Ahmed Mansour
// COP3502, Spring 2019
// ah505081

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "TriePrediction.h"


// Helper function called by printTrie(). (Credit: Dr. S.)
void printTrieHelper(TrieNode *root, char *buffer, int k)
{
	int i;

	if (root == NULL)
		return;

	if (root->count > 0)
		printf("%s (%d)\n", buffer, root->count);

	buffer[k + 1] = '\0';

	for (i = 0; i < 26; i++)
	{
		buffer[k] = 'a' + i;

		printTrieHelper(root->children[i], buffer, k + 1);
	}

	buffer[k] = '\0';
}

// If printing a subtrie, the second parameter should be 1; otherwise, if
// printing the main trie, the second parameter should be 0. (Credit: Dr. S.)
void printTrie(TrieNode *root, int useSubtrieFormatting)
{
	char buffer[1026];

	if (useSubtrieFormatting)
	{
		strcpy(buffer, "- ");
		printTrieHelper(root, buffer, 2);
	}
	else
	{
		strcpy(buffer, "");
		printTrieHelper(root, buffer, 0);
	}
}

// Credit: Dr. S
TrieNode *createTrieNode(void)
{
	return calloc(1, sizeof(TrieNode));
}

// Function that removes all punctuation in a given string, while also changing all letters to lowercase.
void stripPunctuators(char *str)
{
	int i, j = 0, len = strlen(str);
	char *newStr = malloc(sizeof(char) * len);
	
	for (i = 0; i <= len; i++)
	{
		if (isalpha(str[i]))
			newStr[j++] = tolower(str[i]);
	}
	
	strcpy(str, newStr);
	// free temporary string
	free(newStr);
}

// Inserts a string into the given Trie. (Credit: Dr. S)
void insertString(TrieNode *root, char *str)
{
	int i, index, len = strlen(str);
	
	TrieNode *temp;
	if (root == NULL)
		 root = createTrieNode();

	temp = root;
	for (i = 0; i < len; i++)
	{
		// Find the correct index to place characters in trie by subtracting 'a'
		index = tolower(str[i]) - 'a';
		if (temp->children[index] == NULL)
			temp->children[index] = createTrieNode();
			
			temp = temp->children[index];
	}
	//Because we inserted a string into the trie, we increase the count at that node
	temp->count++;
}

// Creates the trie and handles subtrie insertion. (Credit: Dr. S)
TrieNode *buildTrie(char *filename) // entering subtrie data will probably go here... will everyone word except the last have subtrie data?
{
	TrieNode *root = malloc(sizeof(TrieNode));
	TrieNode *temp;
	char previousWord[MAX_CHARACTERS_PER_WORD];
	char buffer[MAX_CHARACTERS_PER_WORD];
	int lastChar;
	FILE *fp;
	
	if ((fp = fopen(filename, "r")) == NULL)
	{
		fprintf(stderr, "Failed to open \"%s\" in buildTrie().\n", filename);
		return NULL;
	}
	// The first word in corpus is handled seperately
	if (fscanf(fp, "%s", buffer) != EOF)
	{
	lastChar = strlen(buffer) - 1;
	stripPunctuators(buffer);
	insertString(root, buffer);
	strcpy(previousWord, buffer);
	}


	while (fscanf(fp, "%s", buffer) != EOF)
	{
		lastChar = strlen(previousWord) - 1;
		stripPunctuators(buffer);
		insertString(root, buffer);
		// If the previous word is the last in the sentence, don't insert the next word in it's subtrie
		if (previousWord[lastChar] == '.' || previousWord[lastChar] == '?' || previousWord[lastChar] == '!')
			continue;
	
		// Grab the node of the previous word that was inserted
		temp = getNode(root, previousWord);
	
		// If the subtrie member in the previous word's node hasn't been made, make one
		if (temp->subtrie == NULL)
			temp->subtrie = malloc(sizeof(TrieNode));
		
		// Insert the current word into the previous word's subtrie
		insertString(temp->subtrie, buffer);
		// Advance the previous word up to the current word
		strcpy(previousWord, buffer); 
	}
	// Close the file
	fclose(fp);
	return root;
}

// Interprets the input file and excecutes the given commands
int processInputFile(TrieNode *root, char *filename)
{
	int i;
	FILE *fp;
	int numWords;
	char buffer[MAX_CHARACTERS_PER_WORD];
	char wordSearch[MAX_CHARACTERS_PER_WORD];
	char tempStr[MAX_CHARACTERS_PER_WORD];
	TrieNode *temp;
	
	// Open the file for reading
	if ((fp = fopen(filename, "r")) == NULL)
		return 1;
	
	while (fscanf(fp, "%s", buffer) != EOF)
	{
		// If command is '!' print the trie
		if (buffer[0] == '!')
		{
			printTrie(root, 0);
		}
		// If the command is '@ we are performing the text prediction feature
		else if (buffer[0] == '@')
		{
			// store the next data from the file, a string
			fscanf(fp, "%s", wordSearch);
			printf("%s", wordSearch);
			// store the next data from the file, an int
			fscanf(fp, "%d", &numWords);
			
			strcpy(tempStr, wordSearch);
			stripPunctuators(wordSearch);
			temp = getNode(root, wordSearch);
			// if the node for the word from the file doesn't exist, leave loop
			if (temp == NULL)
			{
				printf("\n");
				continue;
			}
			
			for (i = 0; i < numWords; i++)
			{
				printf(" %s", tempStr);
				// If current node subtrie hasn't been malloc'd, leave loop
				if (temp->subtrie == NULL)
					break;
				
				
				// Get the next most frequent word
				getMostFrequentWord(temp->subtrie, tempStr);
				// Find the most frequent node and put it in temp
				temp = getNode(root, tempStr);
			}
			printf("\n");
		}
		else
		{
			// buffer must hold a word
			printf("%s\n", buffer);
			temp = getNode(root, buffer);
			if (temp != NULL)
			{
				// Check if the current node has subtrie data
				if (temp->subtrie != NULL)
					printTrie(temp->subtrie, 1);
				else
					printf("(EMPTY)\n");
				
			}
			else
			{
				printf("(INVALID STRING)\n");
			}
		}
	}
	fclose(fp);
	return 0;
}

// Recursively destroy the trie, freeing all memory related to it
TrieNode *destroyTrie(TrieNode *root)
{
	int i = 0;
	if (root == NULL)
		return NULL;
	
	for (i = 0; i < 26; i++)
		destroyTrie(root->children[i]);
	
	// Call destroyTrie for all subtrie members
	destroyTrie(root->subtrie);
	free(root);
	return NULL;
}

// Finds and returns the terminal node that represents the given string
TrieNode *getNode(TrieNode *root, char *str)
{
	int i, index, len;
	TrieNode *temp;
	len = strlen(str);
	
	if (root == NULL)
		return NULL;
	
	temp = root;
	for (i = 0; i < len; i++)
	{
		index = tolower(str[i]) - 'a';
		// Continue going down the trie using the characters in string as the index
		if (temp->children[index] != NULL)
			temp = temp->children[index];
		else
			return NULL;
	}
	// If the terminal node has a count of 0, then the word was never inserted
	if (temp->count > 0)
		return temp;
		
	return NULL;
}

// Helper function to find the most frequent word
void getMostFrequentWordHelper(TrieNode *root, char *currentMostFrequentWord, int *largestCount)
{
	int i;
	if (root == NULL)
		return;
	// If the current node count is larger than any previous count, it becomes the new count
	if (root->count > *largestCount)
	{
		*largestCount = root->count;
	}
	for (i = 0; i < 26; i++)
	{
		getMostFrequentWordHelper(root->children[i], currentMostFrequentWord, largestCount);
	}
}

// Gets the most frequent word in the given trie
void getMostFrequentWord(TrieNode *root, char *str)
{
	int i, index, len, currentCharacter = 0, largestCount = 0;
	char buffer[MAX_CHARACTERS_PER_WORD];
	len = strlen(str);


	if (root == NULL)
		return;
	
	getMostFrequentWordHelper(root, str, &largestCount);
}

// Checks if the given trie contains the given word
int containsWord(TrieNode *root, char *str)
{
	TrieNode *temp = getNode(root, str);
	if (temp == NULL)
		 return 0;
	
	if (temp->count > 0)
		return 1;
	else
		return 0;
}

// Helper function of prefixCount using recursion
int prefixCountHelper(TrieNode *root)
{
	int i, count = 0;;
	if (root == NULL)
		return 0;
	
	// Add the up the counts in children of the trie
	for (i = 0; i < 26; i++)
		count += prefixCountHelper(root->children[i]);
	
	return count + root->count;
}

// Adds up all the counts for words that have the prefix str
int prefixCount(TrieNode *root, char *str)
{
	int i, index, len;
	TrieNode *temp;
	
	len = strlen(str);
	temp = root;
	// Get to the terminal node that represents the word str
	for (i = 0; i < len; i++)
	{
		index = tolower(str[i]) - 'a';
		if (temp->children[index] != NULL)
			temp = temp->children[index];
	else
		return 0;
	}

	return prefixCountHelper(temp);
}

double difficultyRating(void)
{
	return 4.8;
}

double hoursSpent(void)
{
	return 20.0;
}

int main(int argc, char **argv)
{
	TrieNode *trie;
	
	trie = buildTrie(argv[1]);
	
	processInputFile(trie, argv[2]);
	
	destroyTrie(trie);
	return 0;
}
