import React from 'react';
import { View, Text, TextInput, Button, StyleSheet } from 'react-native';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { signUp } from '../../services/auth.service';

const SignUpSchema = z.object({
  username: z.string().min(3, 'Username must be at least 3 characters long'),
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
});

const SignUp = () => {
  const { register, handleSubmit, setValue, formState: { errors } } = useForm({
    resolver: zodResolver(SignUpSchema),
  });

  const onSubmit = async (data) => {
    try {
      await signUp(data);
      // Handle successful sign up (e.g., navigate to another screen)
    } catch (error) {
      // Handle error (e.g., show error message)
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Sign Up</Text>
      <TextInput
        style={styles.input}
        placeholder="Username"
        {...register('username')}
      />
      {errors.username && <Text style={styles.error}>{errors.username.message}</Text>}
      
      <TextInput
        style={styles.input}
        placeholder="Email"
        keyboardType="email-address"
        {...register('email')}
      />
      {errors.email && <Text style={styles.error}>{errors.email.message}</Text>}
      
      <TextInput
        style={styles.input}
        placeholder="Password"
        secureTextEntry
        {...register('password')}
      />
      {errors.password && <Text style={styles.error}>{errors.password.message}</Text>}
      
      <Button title="Sign Up" onPress={handleSubmit(onSubmit)} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 16,
  },
  title: {
    fontSize: 24,
    marginBottom: 24,
    textAlign: 'center',
  },
  input: {
    height: 40,
    borderColor: 'gray',
    borderWidth: 1,
    marginBottom: 12,
    paddingHorizontal: 8,
  },
  error: {
    color: 'red',
    marginBottom: 12,
  },
});

export default SignUp;