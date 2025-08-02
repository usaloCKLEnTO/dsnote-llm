#!/bin/bash
# Simon's LLM Tool Model Comparison Script
# Tests different models with Simon's LLM tool for speed and quality comparison

# Configuration - EDIT THESE TO TEST DIFFERENT MODELS
MODELS=(
    "groq-kimi-k2"
    "groq-llama3-70b" 
    # "claude-3.5-sonnet"
    # "claude-3.5-haiku"
    # "gemini-2.5-flash"
    "gemini-2.5-flash-lite"
    # "groq/qwen/qwen3-32b"
    # "gemini-2.5-pro"
    # "gpt-3.5-turbo"
    # "gpt-4-turbo"
    # "gpt-4o"
    # "gpt-4o-mini"
    "groq-llama-3.3-70b"
    # Add more models here as needed
    # "openrouter/mistralai/mistral-7b-instruct:free"
)

TEST_ITERATIONS=3  # Number of runs per model for averaging

# Test samples with common speech artifacts
declare -a TEST_TEXTS=(
    "um, so like, I think we should, uh, implement this feature"
    "the the command is is broken and nd need to to fix it"
    "uh, let me check the gooble docs for for the answer"
    "Well um basically what I'm trying to say is uh that we need to to refactor this code"
    "So so the problem is is that the nd command doesn't doesn't work properly"
)

# Prompt for cleaning text
PROMPT="Clean up this transcribed speech. Remove filler words like 'um', 'uh', fix grammar, remove duplicate words, and make it clear and concise. Only return the cleaned text, no explanations."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Output file for easy copying
OUTPUT_FILE="llm_model_comparison_$(date +%Y%m%d_%H%M%S).txt"

echo -e "${BLUE}=== Simon's LLM Tool Model Comparison ===${NC}"
echo "Testing ${#MODELS[@]} models with ${#TEST_TEXTS[@]} text samples"
echo "Results will be saved to: $OUTPUT_FILE"
echo ""

# Also write to file
{
    echo "=== Simon's LLM Tool Model Comparison ==="
    echo "Date: $(date)"
    echo "Testing ${#MODELS[@]} models with ${#TEST_TEXTS[@]} text samples"
    echo ""
} > "$OUTPUT_FILE"

# Check if llm is installed
if ! command -v llm &> /dev/null; then
    echo -e "${RED}Error: Simon's LLM tool is not installed or not in PATH${NC}"
    echo "Install with: pip install llm (or pipx install llm)"
    exit 1
fi

# Function to calculate average time
calculate_average() {
    local sum=0
    local count=$#
    for time in "$@"; do
        sum=$(echo "$sum + $time" | bc)
    done
    echo "scale=3; $sum / $count" | bc
}

# Function to test a single model
test_model() {
    local model=$1
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Testing Model: $model${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Also write to file
    {
        echo ""
        echo "========================================="
        echo "MODEL: $model"
        echo "========================================="
    } >> "$OUTPUT_FILE"
    
    local all_times=()
    local sample_num=1
    
    for text in "${TEST_TEXTS[@]}"; do
        echo -e "\n${YELLOW}Sample $sample_num - Input:${NC}"
        echo "\"$text\""
        
        # Write to file
        {
            echo ""
            echo "Sample $sample_num - Input:"
            echo "\"$text\""
        } >> "$OUTPUT_FILE"
        
        local times=()
        local result=""
        
        # Run multiple iterations
        for i in $(seq 1 $TEST_ITERATIONS); do
            # Time the llm command
            local start=$(date +%s.%N)
            result=$(echo "$text" | llm -m "$model" "$PROMPT" 2>&1)
            local end=$(date +%s.%N)
            
            # Check if command was successful
            if [ $? -ne 0 ]; then
                echo -e "${RED}Error with model $model:${NC}"
                echo "$result"
                echo "Error with model $model: $result" >> "$OUTPUT_FILE"
                return
            fi
            
            local duration=$(echo "scale=3; ($end - $start) * 1000" | bc)
            times+=($duration)
            
            # Show output only on first iteration
            if [ $i -eq 1 ]; then
                echo -e "${GREEN}Output:${NC}"
                echo "\"$result\""
                
                # Write to file
                {
                    echo "Output:"
                    echo "\"$result\""
                } >> "$OUTPUT_FILE"
            fi
        done
        
        local avg=$(calculate_average "${times[@]}")
        all_times+=($avg)
        echo -e "${BLUE}Average time (${TEST_ITERATIONS} runs): ${avg}ms${NC}"
        echo "Average time: ${avg}ms" >> "$OUTPUT_FILE"
        
        ((sample_num++))
    done
    
    local overall_avg=$(calculate_average "${all_times[@]}")
    echo -e "\n${GREEN}Overall average for $model: ${overall_avg}ms${NC}"
    
    # Write summary to file
    {
        echo ""
        echo "OVERALL AVERAGE FOR $model: ${overall_avg}ms"
        echo ""
    } >> "$OUTPUT_FILE"
}

# Main execution
echo "Starting tests..."
echo "" | tee -a "$OUTPUT_FILE"

# Test each model
for model in "${MODELS[@]}"; do
    test_model "$model"
done

# Final summary
echo -e "\n${BLUE}=== Test Complete ===${NC}"
echo -e "\n${GREEN}Summary saved to: $OUTPUT_FILE${NC}"

# Create a quick summary at the end of the file
{
    echo ""
    echo "========================================="
    echo "QUICK REFERENCE SUMMARY"
    echo "========================================="
    echo ""
    echo "Models tested:"
    for model in "${MODELS[@]}"; do
        echo "- $model"
    done
    echo ""
    echo "Test samples used:"
    local i=1
    for text in "${TEST_TEXTS[@]}"; do
        echo "$i. \"$text\""
        ((i++))
    done
} >> "$OUTPUT_FILE"

echo ""
echo "Notes:"
echo "- First run of each model may be slower due to loading"
echo "- Some models may not be available without proper API keys"
echo "- Use 'llm keys set' to configure API keys for different providers"
echo "- Results are saved to $OUTPUT_FILE for easy comparison"
echo ""
echo "To add more models:"
echo "1. Edit the MODELS array at the top of this script"
echo "2. Check available models with: llm models list"
echo "3. For local models, install Ollama and use format like 'llama3:8b'"