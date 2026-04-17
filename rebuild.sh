#Clean and nuke prior CMake cache so it doesn’t cling to baseq3:
./clean-artifacts.sh --quake3 --purge-static-dirs
rm -rf ioq3-build/build/emscripten
#Fetch the demo PAK (and fix the permission error):
#chmod +x get-q3demo.sh && ./get-q3demo.sh
#Verify: ioq3-build/demoq3/pak0.pk3 exists
#Build as DEMO with preload ON:
./build-ioq3.sh --demo --preload
#Confirm: ioq3-build/build/emscripten/Release/ioquake3.{js,wasm,data}
#Expect ioquake3.data ≈ 45–55 MB (not 458 MB)
#Verify what’s going to Forge:
ls -lh static/quake3/engine/ioquake3.{js,wasm,data}
du -sh static/quake3 should be < 60 MB total
#Deploy and upgrade:
forge deploy -e development
forge install --upgrade all -e development -s one-atlas-ddag.atlassian.net -p Jira --confirm-scopes --non-interactive
