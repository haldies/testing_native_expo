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
} from 'react-native';

// Memanggil modul Swift yang tadi kita buat
const { MemoryModule } = NativeModules;

function App() {
  const [memories, setMemories] = useState<any[]>([]);

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

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" />
      <View style={styles.header}>
        <Text style={styles.title}>Siri Memories</Text>
      </View>
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
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F2F2F7' },
  header: { padding: 16, backgroundColor: '#fff', borderBottomWidth: 1, borderColor: '#eee' },
  title: { fontSize: 24, fontWeight: 'bold' },
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
});

export default App;
