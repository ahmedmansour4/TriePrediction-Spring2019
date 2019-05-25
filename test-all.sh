#!/bin/bash


# Sean Szumlanski
# COP 3502, Spring 2019

# ===========================
# TriePrediction: test-all.sh
# ===========================
# You can run this script at the command line like so:
#
#   bash test-all.sh
#
# For more details, see the assignment PDF.


################################################################################
# Shell check.
################################################################################

# Running this script with sh instead of bash can lead to false positives on the
# test cases. Yikes! These checks ensure the script is not being run through the
# Bourne shell (or any shell other than bash).

if [ "$BASH" != "/bin/bash" ]; then
  echo ""
  echo " Bloop! Please use bash to run this script, like so: bash test-all.sh"
  echo ""
  exit
fi

if [ -z "$BASH_VERSION" ]; then
  echo ""
  echo " Bloop! Please use bash to run this script, like so: bash test-all.sh"
  echo ""
  exit
fi


################################################################################
# Initialization.
################################################################################

PASS_CNT=0
NUM_TEST_CASES=9
NUM_UNIT_TESTS=7

# Range for unit tests.
FIRST_UNIT_TEST=`expr $NUM_TEST_CASES + 1`
FINAL_UNIT_TEST=`expr $NUM_TEST_CASES + $NUM_UNIT_TESTS`

# Each test case is run twice: once for output check, once for memleak check.
TOTAL_TEST_CNT=`expr $NUM_TEST_CASES + $NUM_UNIT_TESTS`
TOTAL_TEST_CNT=`expr $TOTAL_TEST_CNT + $TOTAL_TEST_CNT`

# +2 below for the warnings and indentation checks.
TOTAL_TEST_CNT=`expr $TOTAL_TEST_CNT + 2`


################################################################################
# Check for commands that are required by this test script.
################################################################################

# This command is necessary in order to run all the test cases in sequence.
if ! [ -x "$(command -v seq)" ]; then
	echo ""
	echo " Error: seq command not found. You might see this message if you're"
	echo "        running this script on an old Mac system. Please be sure to"
	echo "        test your final code on Eustis. Aborting test script."
	echo ""
	exit
fi

# This command is necessary for various warning checks.
if ! [ -x "$(command -v grep)" ]; then
	echo ""
	echo " Error: grep command not found. You might see this message if you're"
	echo "        running this script on an old Mac system. Please be sure to"
	echo "        test your final code on Eustis. Aborting test script."
	echo ""
	exit
fi

# This command is necessary for various warning checks.
if ! [ -x "$(command -v perl)" ]; then
	echo ""
	echo " Error: perl command not found. You might see this message if you're"
	echo "        running this script on an old Mac system. Please be sure to"
	echo "        test your final code on Eustis. Aborting test script."
	echo ""
	exit
fi


################################################################################
# Magical incantations.
################################################################################

# Ensure that obnoxious glibc errors are piped to stderr.
export LIBC_FATAL_STDERR_=1

# Now redirect all local error messages to /dev/null (like "process aborted").
exec 2> /dev/null


################################################################################
# Check that all required files are present.
################################################################################

if [ ! -f TriePrediction.c ]; then
	echo ""
	echo " Error: You must place TriePrediction.c in this directory before"
	echo "        we can proceed. Aborting test script."
	echo ""
	exit
elif [ ! -f TriePrediction.h ]; then
	echo ""
	echo " Error: You must place TriePrediction.h in this directory before"
	echo "        we can proceed. Aborting test script."
	echo ""
	exit
elif [ ! -f UnitTestLauncher.c ]; then
	echo ""
	echo " Error: You must place UnitTestLauncher.c in this directory before"
	echo "        we can proceed. Aborting test script."
	echo ""
	exit
elif [ ! -d sample_output ]; then
	echo ""
	echo " Error: You must place the sample_output folder in this directory"
	echo "        before we can proceed. Aborting test script."
	echo ""
	exit
fi

check_test_case()
{
	local filename=$1

	if [ ! -f $filename ]; then
		echo ""
		echo " Error: You must place $filename in this directory"
		echo "        before we can proceed. Aborting test script."
		echo ""
		exit
	fi
}

check_sample_output()
{
	local filename=$1

	if [ ! -f sample_output/$filename ]; then
		echo ""
		echo " Error: You must place $filename in the"
		echo "        sample_output directory before we can proceed."
		echo "        Aborting test script."
		echo ""
		exit
	fi
}

for i in `seq -f "%02g" 1 $NUM_TEST_CASES`;
do
	check_test_case "corpus$i.txt"
	check_test_case "input$i.txt"
	check_sample_output "output$i.txt"
done

for i in `seq -f "%02g" $FIRST_UNIT_TEST $FINAL_UNIT_TEST`;
do
	check_test_case "UnitTest$i.c"
	check_sample_output "UnitTest$i-output.txt"
done

# Save a backup version of TriePrediction.h to be restored after running this
# script, so that the #define main line ends up back how you had it.
cp TriePrediction.h TriePrediction_backup.h


################################################################################
# Run test cases with input specified at command line (standard test cases).
################################################################################

echo ""
echo "================================================================"
echo "Running input-based test cases..."
echo "================================================================"
echo ""

# Function for running a single test case.
function run_test_case()
{
	local corpus_file=$1
	local input_file=$2
	local output_file=$3

	echo -n "  [Test Case] ./a.out $corpus_file $input_file ... "

	# Ensure that TriePrediction.h is in non-unit test case mode.
	perl -p -i -e 's/^#define main/\/\/#define main/' TriePrediction.h

	# Attempt to compile.
	gcc TriePrediction.c 2> /dev/null
	compile_val=$?

	# Immediately restore header file in case the user terminates the script
	# before we can move on to the next test case.
	cp TriePrediction_backup.h TriePrediction.h

	# Check for compilation failure.
	if [[ $compile_val != 0 ]]; then
		echo "fail (failed to compile)"
		return
	fi

	# Run program. Capture return value to check whether it crashes.
	./a.out $corpus_file $input_file > myoutput.txt 2> /dev/null
	execution_val=$?
	if [[ $execution_val != 0 ]]; then
		echo "fail (program crashed)"
		return
	fi

	# Run diff and capture its return value.
	diff myoutput.txt sample_output/$output_file > /dev/null
	diff_val=$?
	
	# Output results based on diff's return value.
	if  [[ $diff_val != 0 ]]; then
		echo "fail (output mismatch)"
	else
		echo "PASS!"
		PASS_CNT=`expr $PASS_CNT + 1`
	fi
}

for i in `seq -f "%02g" 1 $NUM_TEST_CASES`;
do
	run_test_case "corpus$i.txt" "input$i.txt" "output$i.txt" 2> /dev/null
done


################################################################################
# Run unit tests.
################################################################################

echo ""
echo "================================================================"
echo "Running unit test cases (code-based test cases)..."
echo "================================================================"
echo ""

# Function for running a single unit test.
function run_unit_test()
{
	local testcase_file=$1
	local output_file=$2

	echo -n "  [Unit Test] $testcase_file ... "

	# Ensure that TriePrediction.h is in unit test case mode.
	perl -p -i -e 's/^\/\/(\s*)#define main/#define main/' TriePrediction.h

	# Attempt to compile.
	gcc TriePrediction.c UnitTestLauncher.c $testcase_file 2> /dev/null
	compile_val=$?

	# Immediately restore header file in case the user terminates the script
	# before we can move on to the next test case.
	cp TriePrediction_backup.h TriePrediction.h

	# Check for compilation failure.
	if [[ $compile_val != 0 ]]; then
		echo "fail (failed to compile)"
		return
	fi

	# Run program. Capture return value to check whether it crashes.
	./a.out > myoutput.txt 2> /dev/null
	execution_val=$?
	if [[ $execution_val != 0 ]]; then
		echo "fail (program crashed)"
		return
	fi

	# Run diff and capture its return value.
	diff myoutput.txt sample_output/$output_file > /dev/null
	diff_val=$?
	
	# Output results based on diff's return value.
	if  [[ $diff_val != 0 ]]; then
		echo "fail (output mismatch)"
	else
		echo "PASS!"
		PASS_CNT=`expr $PASS_CNT + 1`
	fi
}

for i in `seq -f "%02g" $FIRST_UNIT_TEST $FINAL_UNIT_TEST`;
do
	run_unit_test "UnitTest$i.c" "UnitTest$i-output.txt" 2> /dev/null
done


################################################################################
# Check for memory leaks: run corpus test cases through valgrind.
################################################################################

echo ""
echo "================================================================"
echo "Checking for memory leaks with valgrind..."
echo "================================================================"
echo ""

# Function for running a single test case through valgrind.
function run_valgrind_test()
{
	local corpus_file=$1
	local input_file=$2
	local output_file=$3

	echo -n "  [Memory Leak Check] ./a.out $corpus_file $input_file ... "

	# Abort immediately if valgrind is not installed on this system.
	if ! [ -x "$(command -v valgrind)" ]; then
		echo "fail (aborted)"
		return
	fi

	# Ensure that TriePrediction.h is in non-unit test case mode.
	perl -p -i -e 's/^#define main/\/\/#define main/' TriePrediction.h

	# Attempt to compile.
	gcc TriePrediction.c -g 2> /dev/null
	compile_val=$?

	# Immediately restore header file in case the user terminates the script
	# before we can move on to the next test case.
	cp TriePrediction_backup.h TriePrediction.h

	# Check for compilation failure.
	if [[ $compile_val != 0 ]]; then
		echo "fail (failed to compile)"
		return
	fi

	# Run program through valgrind. Check whether program crashes.
	valgrind --leak-check=yes ./a.out $corpus_file $input_file > myoutput.txt 2> err.log
	execution_val=$?
	if [[ $execution_val != 0 ]]; then
		echo "fail (program crashed)"
		return
	fi

	# Check output for indication of memory leaks.
	grep --silent "no leaks are possible" err.log
	valgrindfail=$?
	if [[ $valgrindfail != 0 ]]; then
		echo "fail (memory leak detected)"
		return
	fi

	# Run diff and capture its return value.
	diff myoutput.txt sample_output/$output_file > /dev/null
	diff_val=$?
	
	# Output results based on diff's return value.
	if  [[ $diff_val != 0 ]]; then
		echo "fail (output mismatch)"
	else
		echo "PASS!"
		PASS_CNT=`expr $PASS_CNT + 1`
	fi
}

for i in `seq -f "%02g" 1 $NUM_TEST_CASES`;
do
	run_valgrind_test "corpus$i.txt" "input$i.txt" "output$i.txt" 2> /dev/null
done


################################################################################
# Check for memory leaks: run unit tests through valgrind.
################################################################################

echo ""

# Function for running a single unit test case through valgrind.
function run_valgrind_unit_test()
{
	local testcase_file=$1
	local output_file=$2

	echo -n "  [Memory Leak Check] $testcase_file ... "

	# Abort immediately if valgrind is not installed on this system.
	if ! [ -x "$(command -v valgrind)" ]; then
		echo "fail (aborted)"
		return
	fi

	# Ensure that TriePrediction.h is in unit test case mode.
	perl -p -i -e 's/^\/\/(\s*)#define main/#define main/' TriePrediction.h

	# Attempt to compile.
	gcc TriePrediction.c UnitTestLauncher.c $testcase_file -g 2> /dev/null
	compile_val=$?

	# Immediately restore header file in case the user terminates the script
	# before we can move on to the next test case.
	cp TriePrediction_backup.h TriePrediction.h

	# Check for compilation failure.
	if [[ $compile_val != 0 ]]; then
		echo "fail (failed to compile)"
		return
	fi

	# Run program through valgrind. Check whether program crashes.
	valgrind --leak-check=yes ./a.out > myoutput.txt 2> err.log
	execution_val=$?
	if [[ $execution_val != 0 ]]; then
		echo "fail (program crashed)"
		return
	fi

	# Check output for indication of memory leaks.
	grep --silent "no leaks are possible" err.log
	valgrindfail=$?
	if [[ $valgrindfail != 0 ]]; then
		echo "fail (memory leak detected)"
		return
	fi

	# Run diff and capture its return value.
	diff myoutput.txt sample_output/$output_file > /dev/null
	diff_val=$?
	
	# Output results based on diff's return value.
	if  [[ $diff_val != 0 ]]; then
		echo "fail (output mismatch)"
	else
		echo "PASS!"
		PASS_CNT=`expr $PASS_CNT + 1`
	fi
}

for i in `seq -f "%02g" $FIRST_UNIT_TEST $FINAL_UNIT_TEST`;
do
	run_valgrind_unit_test "UnitTest$i.c" "UnitTest$i-output.txt" 2> /dev/null
done


if ! [ -x "$(command -v valgrind)" ]; then
	echo ""
	echo "  ERROR: valgrind is not installed on this system."
fi


############################################################################
# Check for warnings.
############################################################################

echo ""
echo "================================================================"
echo "Checking for compiler warnings..."
echo "================================================================"
echo ""

# Ensure that TriePrediction.h is in non-unit test case mode.
perl -p -i -e 's/^#define main/\/\/#define main/' TriePrediction.h

gcc TriePrediction.c &>> ./err.log
compile_flag=$?

# Immediately restore header file in case the user terminates the script
# before we can move on to the next test case.
cp TriePrediction_backup.h TriePrediction.h

if [[ $compile_flag != 0 ]]; then
	echo "  Failed to compile."
else
	grep --silent "warning" err.log
	warnings_flag=$?

	if [[ $warnings_flag == 0 ]]; then
		echo "  Warnings detected. :("
	else
		echo "  No warnings detected. Hooray!"
		PASS_CNT=`expr $PASS_CNT + 1`
	fi
fi


############################################################################
# Check for tabs vs. spaces.
############################################################################

echo ""
echo "================================================================"
echo "Checking for tabs vs. spaces..."
echo "================================================================"
echo ""

if ! [ -x "$(command -v grep)" ]; then
	echo "  Skipping tabs vs. spaces check; grep not installed. You"
	echo "  might see this message if you're running this script on a"
	echo "  Mac. Please be sure to test your final code on Eustis."
elif ! [ -x "$(command -v awk)" ]; then
	echo "  Skipping tabs vs. spaces check; awk not installed. You"
	echo "  might see this message if you're running this script on a"
	echo "  Mac. Please be sure to test your final code on Eustis."
else
	num_spc_lines=`grep "^ " TriePrediction.c | wc -l | awk '{$1=$1};1'`
	num_tab_lines=`grep "$(printf '^\t')" TriePrediction.c | wc -l | awk '{$1=$1};1'`
	num_und_lines=`grep "$(printf '^[^\t ]')" TriePrediction.c | wc -l | awk '{$1=$1};1'`

	echo "  Number of lines beginning with spaces: $num_spc_lines"
	echo "  Number of lines beginning with tabs: $num_tab_lines"
	echo "  Number of lines with no indentation: $num_und_lines"

	if [ "$num_spc_lines" -gt 0 ] && [ "$num_tab_lines" -gt 0 ]; then
		echo ""
		echo "  Whoa, buddy! It looks like you're starting some lines of code"
		echo "  with tabs, and other lines of code with spaces. You'll need"
		echo "  to choose one or the other."
		echo ""
		echo "  Try running the following commands to see which of your lines"
		echo "  begin with spaces (the first command below) and which ones"
		echo "  begin with tabs (the second command below):"
		echo ""
		echo "     grep \"^ \" TriePrediction.c -n"
		echo "     grep \"\$(printf '^\t')\" TriePrediction.c -n"
	elif [ "$num_spc_lines" -gt 0 ]; then
		echo ""
		echo "  Looks like you're using spaces for all your indentation! (Yay!)"
		PASS_CNT=`expr $PASS_CNT + 1`
	elif [ "$num_tab_lines" -gt 0 ]; then
		echo ""
		echo "  Looks like you're using tabs for all your indentation! (Yay!)"
		PASS_CNT=`expr $PASS_CNT + 1`
	else
		echo ""
		echo "  Whoa, buddy! It looks like none of your code is indented!"
	fi
fi


################################################################################
# Cleanup phase.
################################################################################

# Restore TriePrediction.h to whatever mode it was in before running this script.
if [ -f TriePrediction_backup.h ]; then
	mv TriePrediction_backup.h TriePrediction.h
fi

# Clean up files generated by script.
rm -f a.out
rm -f myoutput.txt
rm -f TriePrediction.o
rm -f err.log


################################################################################
# Final thoughts.
################################################################################

echo ""
echo "================================================================"
echo "Final Report"
echo "================================================================"

if [ $PASS_CNT -eq $TOTAL_TEST_CNT ]; then
	echo ""
	echo "              ,)))))))),,,"
	echo "            ,(((((((((((((((,"
	echo "            )\\\`\\)))))))))))))),"
	echo "     *--===///\`_    \`\`\`((((((((("
	echo "           \\\\\\ b\\  \\    \`\`)))))))"
	echo "            ))\\    |     ((((((((               ,,,,"
	echo "           (   \\   |\`.    ))))))))       ____ ,)))))),"
	echo "                \\, /  )  ((((((((-.___.-\"    \`\"((((((("
	echo "                 \`\"  /    )))))))               \\\`)))))"
	echo "                    /    ((((\`\`                  \\((((("
	echo "              _____|      \`))         /          |)))))"
	echo "             /     \\                 |          / ((((("
	echo "            /  --.__)      /        _\\         /   )))))"
	echo "           /  /    /     /'\`\"~----~\`  \`.       \\   (((("
	echo "          /  /    /     /\`              \`-._    \`-. \`)))"
	echo "         /_ (    /    /\`                    \`-._   \\ (("
	echo "        /__|\`   /   /\`                        \`\\\`-. \\ ')"
	echo "               /  /\`                            \`\\ \\ \\"
	echo "              /  /                                \\ \\ \\"
	echo "             /_ (                                 /_()_("
	echo "            /__|\`                                /__/__|"
	echo ""
	echo "                             Legendary."
	echo ""
	echo "                10/10 would run this program again."
	echo ""
	echo "  CONGRATULATIONS! You appear to be passing all required test"
	echo "  cases! (Now, don't forget to create some extra test cases of"
	echo "  your own. These test cases are not necessarily comprehensive.)"
	echo ""
	echo "================================================================"
	echo "Percy Shelley's \"Ozymandias\" (from corpus07.txt)"
	echo "================================================================"
	echo ""
	echo "             I met a traveller from an antique land"
	echo "         Who said: Two vast and trunkless legs of stone"
	echo "         Stand in the desert... near them, on the sand,"
	echo "        Half sunk, a shattered visage lies, whose frown,"
	echo "          And wrinkled lip, and sneer of cold command,"
	echo "        Tell that its sculptor well those passions read"
	echo "       Which yet survive, stamped on these lifeless things,"
	echo "        The hand that mocked them and the heart that fed:"
	echo ""
	echo "             And on the pedestal these words appear:"
	echo "             'My name is Ozymandias, king of kings:"
	echo "            Look on my works, ye Mighty, and despair!'"
	echo "             Nothing beside remains. Round the decay"
	echo "           Of that colossal wreck, boundless and bare"
	echo "           The lone and level sands stretch far away."
	echo ""
else
	echo "                           ."
	echo "                          \":\""
	echo "                        ___:____     |\"\\/\"|"
	echo "                      ,'        \`.    \\  /"
	echo "                      |  o        \\___/  |"
	echo "                    ~^~^~^~^~^~^~^~^~^~^~^~^~"
	echo ""
	echo "                           (fail whale)"
	echo ""
	echo "  The fail whale is friendly and adorable! He is not here to"
	echo "  demoralize you, but rather, to bring you comfort and joy"
	echo "  in your time of need. \"Keep plugging away,\" he says! \"You"
	echo "  can do this!\""
	echo ""
	echo "  For instructions on how to run these test cases individually"
	echo "  and inspect how your output differs from the expected output,"
	echo "  be sure to consult the assignment PDF."
	echo ""
	echo "  You must also pass the warnings check and the indentation"
	echo "  check in order to part ways with the fail whale."
	echo ""
fi
