import axios from 'axios';

const PAYMENT_API_URL = process.env.PAYMENT_API_URL;

export const createPayment = async (paymentData) => {
    try {
        const response = await axios.post(`${PAYMENT_API_URL}/create`, paymentData);
        return response.data;
    } catch (error) {
        throw new Error(`Payment creation failed: ${error.message}`);
    }
};

export const verifyPayment = async (paymentId) => {
    try {
        const response = await axios.get(`${PAYMENT_API_URL}/verify/${paymentId}`);
        return response.data;
    } catch (error) {
        throw new Error(`Payment verification failed: ${error.message}`);
    }
};

export const refundPayment = async (paymentId) => {
    try {
        const response = await axios.post(`${PAYMENT_API_URL}/refund`, { paymentId });
        return response.data;
    } catch (error) {
        throw new Error(`Payment refund failed: ${error.message}`);
    }
};