 #Fast path to get the ~48 MB demo .data again

#Put the demo pak in the source tree (if you don’t have it already):
./get-q3demo.sh
#Check: ioq3-build/demoq3/pak0.pk3 exists.
#Clean any old static artifacts:
./clean-artifacts.sh --quake3 --purge-static-dirs
#Build in demo preload mode (emits a .data):
./build-ioq3.sh --demo --preload
#Verify:
ls -lh ioq3-build/build/emscripten/Release/ioquake3.{js,wasm,data}
ls -lh static/quake3/engine/ioquake3.{js,wasm,data}
#You should see ioquake3.data ≈ 45–55 MB.
