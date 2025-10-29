import { S3 } from 'aws-sdk';
import { v4 as uuidv4 } from 'uuid';

const s3 = new S3();

export class UploadService {
    private bucketName: string;

    constructor(bucketName: string) {
        this.bucketName = bucketName;
    }

    async uploadFile(file: Express.Multer.File): Promise<string> {
        const fileKey = `${uuidv4()}-${file.originalname}`;
        const params = {
            Bucket: this.bucketName,
            Key: fileKey,
            Body: file.buffer,
            ContentType: file.mimetype,
            ACL: 'public-read',
        };

        try {
            await s3.upload(params).promise();
            return `https://${this.bucketName}.s3.amazonaws.com/${fileKey}`;
        } catch (error) {
            throw new Error(`File upload failed: ${error.message}`);
        }
    }
}