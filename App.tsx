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
} from 'react-native';

const DualCameraView = requireNativeComponent<any>('DualCameraView');

// Memanggil modul Swift yang tadi kita buat
const { MemoryModule } = NativeModules;

function App() {
  const [memories, setMemories] = useState<any[]>([]);
  const [showCamera, setShowCamera] = useState(false);

  useEffect(() => {
    fetchMemories();
  }, []);

  const fetchMemories = async () => {
    try {
      if (!MemoryModule) {
        console.warn("MemoryModule belum terhubung (Hanya berjalan di iOS Native Build).");
        return;
      }
      
      // Mengambil data dari SwiftData via Bridge
      const data = await MemoryModule.getMemories();
      setMemories(data);
    } catch (error) {
      console.error("Gagal mengambil data dari SwiftData:", error);
    }
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
      <StatusBar barStyle="dark-content" />
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
           <DualCameraView style={StyleSheet.absoluteFill} />
           
           {/* Top Bar Overlay */}
           <View style={styles.camTopBar}>
             <TouchableOpacity style={styles.camCircleBtn}><Text style={{color:'#fff'}}>⚡</Text></TouchableOpacity>
             <Text style={styles.camInfoText}>1080p  •  30fps  •  MOV</Text>
             <TouchableOpacity style={styles.camCircleBtn}><Text style={{color:'#fff'}}>⚙️</Text></TouchableOpacity>
           </View>

           {/* Bottom UI Overlay */}
           <View style={styles.camBottomArea}>
              <View style={styles.lensToggleContainer}>
                <TouchableOpacity style={[styles.lensBtn, {backgroundColor: '#FF9500'}]}>
                  <Text style={styles.lensText}>Dual Lens</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.lensBtn}>
                  <Text style={styles.lensText}>Single Lens</Text>
                </TouchableOpacity>
              </View>

              {/* Shutter Button */}
              <View style={styles.shutterContainer}>
                 <TouchableOpacity style={styles.shutterOuter}>
                   <View style={styles.shutterInner} />
                 </TouchableOpacity>
              </View>
           </View>

           <TouchableOpacity 
             onPress={() => setShowCamera(false)} 
             style={styles.closeCamBtn}
           >
             <Text style={styles.closeCamText}>X</Text>
           </TouchableOpacity>
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
    borderRadius: 12,
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
  camInfoText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
    backgroundColor: 'rgba(0,0,0,0.3)',
    paddingVertical: 4,
    paddingHorizontal: 12,
    borderRadius: 12,
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
});

export default App;
