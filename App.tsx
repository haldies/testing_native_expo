import React, { useEffect, useState } from 'react';
import {
  SafeAreaView,
  StatusBar,
  StyleSheet,
  Text,
  View,
  NativeModules,
  ScrollView,
  Image,
  TouchableOpacity,
  Alert,
  requireNativeComponent,
  UIManager,
  findNodeHandle,
} from 'react-native';

const DualCameraView = requireNativeComponent<any>('DualCameraView');
const { MemoryModule, DualCameraViewManager } = NativeModules;

function App() {
  const [memories, setMemories] = useState<any[]>([]);
  const [showCamera, setShowCamera] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [isDualLens, setIsDualLens] = useState(true);
  const [fps, setFps] = useState(30);
  const [res, setRes] = useState('1080p');
  const [isMultiCamSupported, setIsMultiCamSupported] = useState(true);
  
  const camRef = React.useRef(null);

  useEffect(() => {
    fetchMemories();
    checkSupport();
  }, []);

  const checkSupport = async () => {
    try {
      if (MemoryModule?.checkMultiCamSupport) {
        const supported = await MemoryModule.checkMultiCamSupport();
        setIsMultiCamSupported(supported);
        if (!supported) {
          setIsDualLens(false);
        }
      }
    } catch (e) {
      console.error(e);
    }
  };

  const fetchMemories = async () => {
    try {
      if (MemoryModule?.getMemories) {
        const data = await MemoryModule.getMemories();
        setMemories(data);
      }
    } catch (e) {
      console.error(e);
    }
  };

  const toggleLens = (dual: boolean) => {
    setIsDualLens(dual);
    const node = findNodeHandle(camRef.current);
    if (node) {
      UIManager.dispatchViewManagerCommand(
        node,
        UIManager.getViewManagerConfig('DualCameraView').Commands.setIsDualMode,
        [dual]
      );
    }
  };

  const handleRecord = () => {
    const node = findNodeHandle(camRef.current);
    if (node) {
      UIManager.dispatchViewManagerCommand(
        node,
        UIManager.getViewManagerConfig('DualCameraView').Commands.toggleRecording,
        []
      );
    }
  };

  const handleFlip = () => {
    const node = findNodeHandle(camRef.current);
    if (node) {
      UIManager.dispatchViewManagerCommand(
        node,
        UIManager.getViewManagerConfig('DualCameraView').Commands.flipCamera,
        []
      );
    }
  };

  const changeFPS = (newFps: number) => {
    setFps(newFps);
    const node = findNodeHandle(camRef.current);
    if (node) {
      UIManager.dispatchViewManagerCommand(
        node,
        UIManager.getViewManagerConfig('DualCameraView').Commands.setFPS,
        [newFps]
      );
    }
  };

  const changeRes = (newRes: string) => {
    setRes(newRes);
    const node = findNodeHandle(camRef.current);
    if (node) {
      UIManager.dispatchViewManagerCommand(
        node,
        UIManager.getViewManagerConfig('DualCameraView').Commands.setResolution,
        [newRes]
      );
    }
  };

  const handleRecordingState = (event: any) => {
    setIsRecording(event.nativeEvent.isRecording);
  };

  const handleRefreshShortcuts = async () => {
    try {
      if (MemoryModule?.refreshShortcuts) {
        await MemoryModule.refreshShortcuts();
        Alert.alert("Sukses", "Siri Shortcuts telah didaftarkan ke sistem iPhone! Silakan cek aplikasi Shortcuts sekarang.");
      }
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle={showCamera ? "light-content" : "dark-content"} />
      <View style={styles.header}>
        <Text style={styles.title}>Siri Memories</Text>
        <View style={{ flexDirection: 'row', gap: 8 }}>
          <TouchableOpacity onPress={() => setShowCamera(!showCamera)} style={[styles.shortcutBtn, { backgroundColor: '#34C759' }]}>
            <Text style={styles.btnText}>{showCamera ? "Tutup Kamera" : "Dual Kamera"}</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={handleRefreshShortcuts} style={styles.shortcutBtn}>
            <Text style={styles.btnText}>Siri</Text>
          </TouchableOpacity>
        </View>
      </View>

      {showCamera ? (
        <View style={StyleSheet.absoluteFill}>
           <DualCameraView 
             ref={camRef}
             style={StyleSheet.absoluteFill} 
             onRecordingStateChanged={handleRecordingState}
           />
           
           {/* Top Bar Overlay */}
           <View style={styles.camTopBar}>
             <TouchableOpacity style={styles.camCircleBtn}><Text style={{color:'#fff'}}>⚡</Text></TouchableOpacity>
             <View style={styles.camInfoBadge}>
                <TouchableOpacity onPress={() => changeRes(res === '1080p' ? '4K' : '1080p')}>
                  <Text style={styles.camInfoText}>{res}</Text>
                </TouchableOpacity>
                <Text style={styles.camInfoText}>  •  </Text>
                <TouchableOpacity onPress={() => changeFPS(fps === 30 ? 60 : 30)}>
                  <Text style={styles.camInfoText}>{fps}fps</Text>
                </TouchableOpacity>
                <Text style={styles.camInfoText}>  •  MOV</Text>
             </View>
             <View style={{ gap: 12 }}>
                <TouchableOpacity style={styles.camCircleBtn}><Text style={{color:'#fff'}}>⚙️</Text></TouchableOpacity>
                {!isDualLens && (
                  <TouchableOpacity onPress={handleFlip} style={styles.camCircleBtn}>
                    <Text style={{color:'#fff'}}>🔄</Text>
                  </TouchableOpacity>
                )}
             </View>
           </View>

           {/* Bottom UI Overlay */}
           <View style={styles.camBottomArea}>
              <View style={styles.lensToggleContainer}>
                <TouchableOpacity 
                  onPress={() => isMultiCamSupported && toggleLens(true)}
                  style={[styles.lensBtn, isDualLens && {backgroundColor: '#FF9500'}, !isMultiCamSupported && {opacity: 0.5}]}
                >
                  <Text style={styles.lensText}>Dual Lens</Text>
                </TouchableOpacity>
                <TouchableOpacity 
                  onPress={() => toggleLens(false)}
                  style={[styles.lensBtn, !isDualLens && {backgroundColor: '#FF9500'}]}
                >
                  <Text style={styles.lensText}>Single Lens</Text>
                </TouchableOpacity>
              </View>

              {/* Shutter Button */}
              <View style={styles.shutterContainer}>
                 <TouchableOpacity onPress={handleRecord} style={styles.shutterOuter}>
                   <View style={[styles.shutterInner, isRecording && { borderRadius: 8, width: 40, height: 40 }]} />
                 </TouchableOpacity>
              </View>
           </View>

           <TouchableOpacity 
             onPress={() => setShowCamera(false)} 
             style={styles.closeCamBtn}
           >
             <Text style={styles.closeCamText}>X</Text>
           </TouchableOpacity>

           {/* Orange Guide Frame for Single Lens */}
           {!isDualLens && (
             <View style={styles.centerFrameContainer} pointerEvents="none">
               <View style={styles.orangeFrame} />
             </View>
           )}
        </View>
      ) : (
        <ScrollView contentContainerStyle={styles.list}>
        {memories.length === 0 ? (
          <Text style={styles.emptyText}>Belum ada Memory yang disimpan dari Siri.</Text>
        ) : (
          memories.map((memory, index) => (
            <View key={index} style={styles.card}>
              {memory.imageData && (
                <Image
                  source={{ uri: `data:image/jpeg;base64,${memory.imageData}` }}
                  style={styles.image}
                  resizeMode="cover"
                />
              )}
              <Text style={styles.caption}>{memory.caption}</Text>
              <Text style={styles.date}>
                {new Date(memory.date * 1000).toLocaleString('id-ID')}
              </Text>
            </View>
          ))
        )}
        </ScrollView>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F2F2F7' },
  header: { 
    padding: 16, 
    backgroundColor: '#fff', 
    borderBottomWidth: 1, 
    borderColor: '#eee',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  title: { fontSize: 20, fontWeight: 'bold' },
  shortcutBtn: {
    backgroundColor: '#007AFF',
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 8,
  },
  btnText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
  },
  list: { padding: 16, gap: 16 },
  emptyText: { textAlign: 'center', marginTop: 50, color: '#888' },
  card: {
    backgroundColor: '#fff',
    borderRadius: 16,
    overflow: 'hidden',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  image: { width: '100%', height: 200, backgroundColor: '#e1e1e1' },
  caption: { fontSize: 18, fontWeight: '600', margin: 12, marginBottom: 4 },
  date: { fontSize: 12, color: '#666', marginHorizontal: 12, marginBottom: 12 },
  closeCamBtn: {
    position: 'absolute',
    top: 40,
    right: 20,
    width: 40,
    height: 40,
    backgroundColor: 'rgba(0,0,0,0.5)',
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  closeCamText: { color: '#fff', fontSize: 18, fontWeight: 'bold' },
  camTopBar: {
    position: 'absolute',
    top: 50,
    left: 20,
    right: 20,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  camCircleBtn: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(255,255,255,0.2)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  camInfoBadge: {
    flexDirection: 'row',
    backgroundColor: 'rgba(0,0,0,0.3)',
    paddingVertical: 4,
    paddingHorizontal: 12,
    borderRadius: 12,
  },
  camInfoText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
  },
  camBottomArea: {
    position: 'absolute',
    bottom: 40,
    left: 0,
    right: 0,
    alignItems: 'center',
  },
  lensToggleContainer: {
    flexDirection: 'row',
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 20,
    padding: 2,
    marginBottom: 30,
  },
  lensBtn: {
    paddingVertical: 8,
    paddingHorizontal: 20,
    borderRadius: 18,
  },
  lensText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
  shutterContainer: {
    marginBottom: 20,
  },
  shutterOuter: {
    width: 80,
    height: 80,
    borderRadius: 40,
    borderWidth: 4,
    borderColor: '#fff',
    justifyContent: 'center',
    alignItems: 'center',
  },
  shutterInner: {
    width: 66,
    height: 66,
    borderRadius: 33,
    backgroundColor: '#FF3B30',
  },
  centerFrameContainer: {
    ...StyleSheet.absoluteFill,
    justifyContent: 'center',
    alignItems: 'center',
  },
  orangeFrame: {
    width: '90%',
    height: 200,
    borderWidth: 2,
    borderColor: '#FF9500',
    backgroundColor: 'transparent',
  },
});

export default App;
