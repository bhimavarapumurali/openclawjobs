param(
    [string]$TavilyApiKey = "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",
    [string]$TelegramBotToken = "8697200127:AAE0J7hvXVKEzaJrRt4qk01JSOIfVoKba6Y",
    [string]$TelegramChannel = "@mkai_news"
)

# Fetch AI news from Tavily
$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer $TavilyApiKey"
}

$body = @{
    query = "latest trending artificial intelligence AI developments tools research breakthroughs 2026"
    search_depth = "basic"
    max_results = 10
    include_answer = $true
    days = 1
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "https://api.tavily.com/search" -Method Post -Headers $headers -Body $body -TimeoutSec 30
} catch {
    Write-Host "Tavily API error: $_"
    exit 1
}

$results = $response.results
if (-not $results -or $results.Count -eq 0) {
    Write-Host "No results from Tavily"
    exit 1
}

# Format the newsletter
$date = (Get-Date).ToString("dddd, MMMM d, yyyy")
$emoji = "🤖"

$header = "${emoji} <b>MK AI News Daily</b> 🦾$([Environment]::NewLine)<b>${date}</b>$([Environment]::NewLine)$([Environment]::NewLine))"

$newsItems = @()
for ($i = 0; $i -lt [Math]::Min(6, $results.Count); $i++) {
    $item = $results[$i]
    $title = $item.title
    $url = $item.url
    $snippet = $item.content
    if ([string]::IsNullOrWhiteSpace($snippet)) { $snippet = $item.url }
    $newsItems += "$($i+1). <a href=""$url""><b>$title</b></a>`n   $snippet"
}

$footer = "$([Environment]::NewLine)<i>🛠 Built with Tavily API | For tech enthusiasts exploring the AI landscape</i>"

$message = $header + ($newsItems -join "$([Environment]::NewLine)$([Environment]::NewLine)") + $footer

# Post to Telegram
$tgUrl = "https://api.telegram.org/bot${TelegramBotToken}/sendMessage"
$encoding = [System.Text.Encoding]::UTF8
$tgBodyHt = @{
    chat_id = $TelegramChannel
    text = $message
    parse_mode = "HTML"
    disable_web_page_preview = $false
}
$jsonBytes = $encoding.GetBytes(($tgBodyHt | ConvertTo-Json -Compress))
try {
    $tgResponse = Invoke-RestMethod -Uri $tgUrl -Method Post -ContentType "application/json; charset=utf-8" -Body $jsonBytes -TimeoutSec 30
    if ($tgResponse.ok) {
        Write-Host "Posted successfully to $TelegramChannel"
    } else {
        Write-Host "Telegram error: $($tgResponse.description)"
    }
} catch {
    Write-Host "Telegram post error: $_"
    exit 1
}
