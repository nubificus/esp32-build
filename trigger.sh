# Your input JSON
#json_input='{ "apps":[ {"repo":"nubificus/esp-idf-http-camera","branch":"feat_nbfc"}, {"repo":"nubificus/esp32-hello_world","branch":"main"}, {"repo":"nubificus/esp32-ota-update","branch":"feat_http_server"} ], "targets":["esp32"], "keys":[""] }'
json_input='{ "apps":[ {"repo":"nubificus/esp32-ota-update","branch":"feat_http_server"} ], "targets":["esp32"], "keys":[""] }'

# Properly escape the JSON using jq and convert to a single line
escaped_json_input=$(echo "$json_input" | jq -Rc .)

# Print the escaped JSON for debugging
echo "Escaped JSON Input: $escaped_json_input"

# Use the escaped JSON in your curl command
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: token $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/nubificus/esp32-build/actions/workflows/ci.yml/dispatches \
  -d "{ \"ref\": \"feat_build_ondemand\", \"inputs\": { \"json_input\": $escaped_json_input } }"
