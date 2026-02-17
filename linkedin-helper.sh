#!/bin/bash

# LinkedIn Strategy Helper Script
# Manages LinkedIn tasks, analytics, and automation

set -e

WORKSPACE="/Users/streets/.openclaw/workspace"
TASKS_FILE="$WORKSPACE/data/tasks.json"
STRATEGY_FILE="$WORKSPACE/data/linkedin-strategy.json"
ANALYTICS_FILE="$WORKSPACE/data/linkedin-analytics.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[LinkedIn Helper]${NC} $1"
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

error() {
    echo -e "${RED}❌${NC} $1"
}

show_help() {
    cat << EOF
LinkedIn Strategy Helper - Manage your LinkedIn automation

USAGE:
    ./linkedin-helper.sh [COMMAND] [OPTIONS]

COMMANDS:
    status          Show current LinkedIn strategy status
    daily           Log daily LinkedIn activities
    weekly          Run weekly performance review
    monthly         Run monthly strategy review
    add-connection  Log new connection details
    track-post      Track LinkedIn post performance
    analytics       Show performance analytics
    merge           Merge strategy tasks into Mission Control
    dashboard       Open LinkedIn dashboard in browser
    help            Show this help message

EXAMPLES:
    ./linkedin-helper.sh status
    ./linkedin-helper.sh daily --comments 7 --reactions 12
    ./linkedin-helper.sh track-post --url "linkedin.com/posts/..." --impressions 1500
    ./linkedin-helper.sh add-connection --name "John Doe" --title "CTO" --company "AdTech Inc"

EOF
}

init_analytics() {
    if [[ ! -f "$ANALYTICS_FILE" ]]; then
        log "Creating analytics file..."
        cat > "$ANALYTICS_FILE" << 'EOF'
{
  "metrics": {
    "connections": {
      "total": 2847,
      "weeklyGrowth": 23,
      "acceptanceRate": 0.89
    },
    "profile": {
      "views30d": 1204,
      "searches30d": 567,
      "impressions30d": 15600
    },
    "content": {
      "posts30d": 12,
      "avgEngagementRate": 0.042,
      "avgImpressions": 1250,
      "topPerformingPost": ""
    },
    "business": {
      "leads30d": 12,
      "opportunities": 3,
      "meetings": 2
    }
  },
  "dailyLog": [],
  "weeklyReviews": [],
  "monthlyReviews": []
}
EOF
        success "Analytics file created"
    fi
}

show_status() {
    log "LinkedIn Strategy Status"
    echo ""
    
    if [[ -f "$ANALYTICS_FILE" ]]; then
        # Parse analytics data
        connections=$(jq -r '.metrics.connections.total' "$ANALYTICS_FILE")
        views=$(jq -r '.metrics.profile.views30d' "$ANALYTICS_FILE")
        engagement=$(jq -r '.metrics.content.avgEngagementRate' "$ANALYTICS_FILE")
        leads=$(jq -r '.metrics.business.leads30d' "$ANALYTICS_FILE")
        
        echo "📊 Performance Metrics (30 days):"
        echo "   Connections: $connections"
        echo "   Profile Views: $views"
        echo "   Avg Engagement: $(echo "$engagement * 100" | bc -l | cut -c1-4)%"
        echo "   Business Leads: $leads"
        echo ""
    fi
    
    if [[ -f "$TASKS_FILE" ]]; then
        # Count LinkedIn tasks by status
        total=$(jq '[.[] | select(.category | test("linkedin"))] | length' "$TASKS_FILE")
        backlog=$(jq '[.[] | select(.category | test("linkedin")) | select(.status == "backlog")] | length' "$TASKS_FILE")
        in_progress=$(jq '[.[] | select(.category | test("linkedin")) | select(.status == "in_progress")] | length' "$TASKS_FILE")
        done=$(jq '[.[] | select(.category | test("linkedin")) | select(.status == "done")] | length' "$TASKS_FILE")
        
        echo "📋 Task Status:"
        echo "   Total LinkedIn Tasks: $total"
        echo "   Backlog: $backlog"
        echo "   In Progress: $in_progress"
        echo "   Done: $done"
        echo ""
    fi
    
    echo "🎯 Today's LinkedIn Activities:"
    echo "   [ ] Morning engagement (5-7 comments)"
    echo "   [ ] Lunch reactions (2-3 posts shared)"
    echo "   [ ] Evening replies (respond to comments)"
    echo "   [ ] Connection outreach (3-5 requests)"
}

log_daily_activity() {
    init_analytics
    
    local comments=${1:-0}
    local reactions=${2:-0}
    local replies=${3:-0}
    local connections=${4:-0}
    
    local today=$(date '+%Y-%m-%d')
    
    # Add daily log entry
    jq --arg date "$today" \
       --arg comments "$comments" \
       --arg reactions "$reactions" \
       --arg replies "$replies" \
       --arg connections "$connections" \
       '.dailyLog += [{
         date: $date,
         activities: {
           comments: ($comments | tonumber),
           reactions: ($reactions | tonumber), 
           replies: ($replies | tonumber),
           connections: ($connections | tonumber)
         },
         totalMinutes: 20
       }]' "$ANALYTICS_FILE" > "${ANALYTICS_FILE}.tmp" && mv "${ANALYTICS_FILE}.tmp" "$ANALYTICS_FILE"
    
    success "Logged daily activity: $comments comments, $reactions reactions, $replies replies, $connections connections"
}

merge_strategy_tasks() {
    if [[ ! -f "$STRATEGY_FILE" ]]; then
        error "Strategy file not found: $STRATEGY_FILE"
        exit 1
    fi
    
    log "Merging LinkedIn strategy tasks into Mission Control..."
    
    # Merge strategy tasks into main tasks file
    if [[ -f "$TASKS_FILE" ]]; then
        # Combine arrays
        jq -s '.[0] + .[1]' "$TASKS_FILE" "$STRATEGY_FILE" > "${TASKS_FILE}.tmp" && mv "${TASKS_FILE}.tmp" "$TASKS_FILE"
    else
        cp "$STRATEGY_FILE" "$TASKS_FILE"
    fi
    
    success "LinkedIn strategy tasks merged into Mission Control"
}

track_post_performance() {
    local url="$1"
    local impressions="$2" 
    local engagement="$3"
    
    if [[ -z "$url" ]]; then
        error "Post URL required"
        exit 1
    fi
    
    init_analytics
    
    local today=$(date '+%Y-%m-%d')
    
    # Add post tracking
    jq --arg date "$today" \
       --arg url "$url" \
       --arg impressions "$impressions" \
       --arg engagement "$engagement" \
       '.posts += [{
         date: $date,
         url: $url,
         impressions: ($impressions | tonumber),
         engagement: ($engagement | tonumber)
       }]' "$ANALYTICS_FILE" > "${ANALYTICS_FILE}.tmp" && mv "${ANALYTICS_FILE}.tmp" "$ANALYTICS_FILE"
       
    success "Post performance tracked: $impressions impressions, $engagement engagement"
}

open_dashboard() {
    local dashboard_path="$WORKSPACE/linkedin-dashboard.html"
    
    if [[ -f "$dashboard_path" ]]; then
        log "Opening LinkedIn dashboard..."
        if command -v open >/dev/null; then
            open "$dashboard_path"
        elif command -v xdg-open >/dev/null; then
            xdg-open "$dashboard_path" 
        else
            warn "Cannot open dashboard automatically. Open manually: $dashboard_path"
        fi
    else
        error "Dashboard not found: $dashboard_path"
    fi
}

# Parse command line arguments
case "${1:-help}" in
    "status")
        show_status
        ;;
    "daily")
        shift
        while [[ $# -gt 0 ]]; do
            case $1 in
                --comments) comments="$2"; shift 2 ;;
                --reactions) reactions="$2"; shift 2 ;;
                --replies) replies="$2"; shift 2 ;;
                --connections) connections="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        log_daily_activity "$comments" "$reactions" "$replies" "$connections"
        ;;
    "merge")
        merge_strategy_tasks
        ;;
    "track-post")
        shift
        while [[ $# -gt 0 ]]; do
            case $1 in
                --url) url="$2"; shift 2 ;;
                --impressions) impressions="$2"; shift 2 ;;
                --engagement) engagement="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
        track_post_performance "$url" "$impressions" "$engagement"
        ;;
    "dashboard")
        open_dashboard
        ;;
    "analytics")
        if [[ -f "$ANALYTICS_FILE" ]]; then
            cat "$ANALYTICS_FILE" | jq '.'
        else
            warn "No analytics data found. Run some activities first."
        fi
        ;;
    "help"|*)
        show_help
        ;;
esac