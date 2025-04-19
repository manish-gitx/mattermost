#!/bin/bash
# Mattermost Search Performance Benchmark Script
# This script compares search performance between SQL and Elasticsearch

# Configuration
MM_SERVER="http://localhost:8065"  # Mattermost server URL
API_PATH="/api/v4"                 # API endpoint
SEARCH_TERM="important"            # Term to search for
TEAM_NAME="your-team"              # Team name
NUM_RUNS=10                        # Number of tests to run
BEARER_TOKEN=""                    # Your authentication token (obtain from browser dev tools)

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "Mattermost Search Performance Benchmark"
echo "======================================="
echo

if [ -z "$BEARER_TOKEN" ]; then
    echo "Please set your BEARER_TOKEN in the script"
    exit 1
fi

# Function to measure search time
measure_search() {
    local search_type=$1
    local url="$MM_SERVER$API_PATH/teams/name/$TEAM_NAME/posts/search"
    local data="{\"terms\":\"$SEARCH_TERM\",\"is_or_search\":false}"
    local header="Authorization: Bearer $BEARER_TOKEN"
    local content_type="Content-Type: application/json"
    
    # Set search engine via header if needed
    if [ "$search_type" == "elasticsearch" ]; then
        local engine="X-Search-Engine: elasticsearch"
        echo -e "${BLUE}Running Elasticsearch search...${NC}"
    elif [ "$search_type" == "database" ]; then
        local engine="X-Search-Engine: database"
        echo -e "${BLUE}Running Database search...${NC}"
    else
        local engine=""
        echo -e "${BLUE}Running default search...${NC}"
    fi
    
    # Run multiple times and calculate average
    local total_time=0
    local min_time=999999
    local max_time=0
    
    for i in $(seq 1 $NUM_RUNS); do
        echo -n "Test run $i: "
        
        # Measure time for the search request
        start=$(date +%s.%N)
        if [ -z "$engine" ]; then
            response=$(curl -s -w "%{time_total}\n" -X POST -H "$header" -H "$content_type" -d "$data" "$url" -o /dev/null)
        else
            response=$(curl -s -w "%{time_total}\n" -X POST -H "$header" -H "$engine" -H "$content_type" -d "$data" "$url" -o /dev/null)
        fi
        time_taken=$response
        
        echo "$time_taken seconds"
        
        # Update statistics
        total_time=$(echo "$total_time + $time_taken" | bc)
        min_time=$(echo "if ($time_taken < $min_time) $time_taken else $min_time" | bc)
        max_time=$(echo "if ($time_taken > $max_time) $time_taken else $max_time" | bc)
    done
    
    # Calculate and display average
    avg_time=$(echo "scale=4; $total_time / $NUM_RUNS" | bc)
    echo -e "${GREEN}Average search time: $avg_time seconds${NC}"
    echo -e "${GREEN}Min search time: $min_time seconds${NC}"
    echo -e "${GREEN}Max search time: $max_time seconds${NC}"
    echo
    
    # Return the average time
    echo $avg_time
}

# Main benchmark process
echo "=== Testing Default Search ==="
default_avg=$(measure_search "default")

echo "=== Testing Database Search ==="
db_avg=$(measure_search "database")

echo "=== Testing Elasticsearch Search ==="
es_avg=$(measure_search "elasticsearch")

# Calculate improvement percentage
if (( $(echo "$db_avg > 0" | bc -l) )); then
    es_improvement=$(echo "scale=2; (($db_avg - $es_avg) / $db_avg) * 100" | bc)
    echo -e "${GREEN}Elasticsearch is approximately $es_improvement% faster than database search${NC}"
fi

echo
echo "Benchmark Summary:"
echo "-----------------"
echo "Default search engine: $default_avg seconds average"
echo "Database search: $db_avg seconds average"
echo "Elasticsearch search: $es_avg seconds average" 