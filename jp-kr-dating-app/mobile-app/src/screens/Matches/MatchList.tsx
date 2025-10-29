import React from 'react';
import { View, Text, FlatList, StyleSheet } from 'react-native';
import { useQuery } from 'react-query';
import axios from '../../api/axios';

const MatchList = () => {
  const { data: matches, isLoading, error } = useQuery('matches', async () => {
    const response = await axios.get('/matches');
    return response.data;
  });

  if (isLoading) {
    return (
      <View style={styles.container}>
        <Text>Loading...</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.container}>
        <Text>Error loading matches</Text>
      </View>
    );
  }

  return (
    <FlatList
      data={matches}
      keyExtractor={(item) => item.id.toString()}
      renderItem={({ item }) => (
        <View style={styles.matchItem}>
          <Text>{item.name}</Text>
          <Text>{item.age} years old</Text>
        </View>
      )}
    />
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  matchItem: {
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#ccc',
  },
});

export default MatchList;