# Your input JSON
#json_input='{ "apps":[ {"repo":"nubificus/esp-idf-http-camera","branch":"feat_nbfc"}, {"repo":"nubificus/esp32-hello_world","branch":"main"}, {"repo":"nubificus/esp32-ota-update","branch":"feat_http_server"} ], "targets":["esp32"], "keys":[""] }'
#json_input='{ "apps":[ {"repo":"nubificus/esp32-ota-update","branch":"feat_http_server","version":"0.3.0","type":"thermo"},{"repo":"nubificus/esp32-ota-update","branch":"feat_http_server","version":"0.2.0","type":"thermo"},{"repo":"nubificus/esp32-ota-update","branch":"feat_http_server","version":"0.3.0","type":"switch"},{"repo":"nubificus/esp32-ota-update","branch":"feat_http_server","version":"0.2.0","type":"switch"} ], "targets":["esp32s2","esp32s3"], "keys":[""] }'
#json_input='{ "apps":[ {"repo":"nubificus/esp32-ota-update","branch":"feat_http_server","version":"0.3.0","type":"thermo"},{"repo":"nubificus/esp32-ota-update","branch":"feat_http_server","version":"0.2.0","type":"thermo"},{"repo":"nubificus/esp32-ota-update","branch":"feat_http_server","version":"0.3.0","type":"switch"},{"repo":"nubificus/esp32-ota-update","branch":"feat_http_server","version":"0.2.0","type":"switch"} ], "targets":["esp32"], "keys":["ESP32_KEY1","ESP32_KEY2"] }'
#json_input='{ "apps":[ {"repo":"nubificus/esp32-ota-update","branch":"feat_example_repo","version":"0.4.1","type":"thermo"} ], "targets":["esp32"], "keys":["ESP32_KEY1","ESP32_KEY2"] }'
# json_input='{ "apps":[ {"repo":"nubificus/fmnist-esp-ota","branch":"feat_build_actions","version":"0.4.1","type":"fmnist", "model":"models/resnet8_frozen.tflite" } ], "targets":["esp32","esp32s2","esp32s3", "esp32c6"], "keys":[""] }'
json_input='{ "apps":[ {"repo":"nubificus/fmnist-esp-ota",
						"branch":"feat_build_actions",
						"version":"0.4.1",
						"type":"fmnist",
						"model":"models/simple_cnn_tf_frozen.tflite",
						"tensor_allocation_space":"204800",
						} ],
			"flash_sizes":["4MB","8MB"],
			"targets":["esp32s3"],
			"keys":[""] }'
#json_input='{"apps":[{"repo":"nubificus/esp32-ota-update","branch":"feat_http_server"}],"targets":["esp32","esp32s2","esp32s3"],"keys":["ESP32_KEY1","ESP32_KEY2"]}'

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
  -d "{ \"ref\": \"feat_tflite\", \"inputs\": { \"json_input\": $escaped_json_input } }"