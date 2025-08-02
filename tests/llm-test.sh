#!/bin/bash
TEST_TEXT="um, so like, I think we should, uh, implement this feature"

# Using the FULL PATH to Claude Code
CLAUDE_PATH="/var/home/numble/.claude/local/node_modules/.bin/claude"

echo "Testing Claude Code with full path:"
time $CLAUDE_PATH -p "Clean up this text, removing filler words: $TEST_TEXT"

# For comparison with LLM tool (if you want to test it)
echo -e "\nTesting LLM tool (if installed):"
time echo "$TEST_TEXT" | llm -m groq-llama3-70b "Clean up this text, removing filler words"