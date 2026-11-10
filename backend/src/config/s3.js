import { S3Client, PutObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { v4 as uuidv4 } from 'uuid';
import path from 'path';

/**
 * AWS S3 client instance configured from environment variables.
 */
const s3Client = new S3Client({
  region: process.env.AWS_REGION || 'ap-south-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
  }
});

const BUCKET = process.env.AWS_S3_BUCKET || 'connect4people-uploads';

/**
 * Upload a file buffer to S3 and return the public URL.
 * @param {Buffer} fileBuffer - The file buffer to upload
 * @param {string} originalName - Original filename (used for extension)
 * @param {string} folder - S3 folder / prefix (e.g. 'photos', 'avatars')
 * @returns {Promise<string>} The public URL of the uploaded file
 */
export const uploadToS3 = async (fileBuffer, originalName, folder = 'photos') => {
  const ext = path.extname(originalName);
  const key = `${folder}/${uuidv4()}${ext}`;

  const command = new PutObjectCommand({
    Bucket: BUCKET,
    Key: key,
    Body: fileBuffer,
    ContentType: getContentType(ext)
  });

  await s3Client.send(command);

  return `https://${BUCKET}.s3.${process.env.AWS_REGION || 'ap-south-1'}.amazonaws.com/${key}`;
};

/**
 * Delete a file from S3 by its full URL.
 * @param {string} fileUrl - The full S3 URL of the file to delete
 * @returns {Promise<void>}
 */
export const deleteFromS3 = async (fileUrl) => {
  const url = new URL(fileUrl);
  const key = url.pathname.slice(1); // remove leading slash

  const command = new DeleteObjectCommand({
    Bucket: BUCKET,
    Key: key
  });

  await s3Client.send(command);
};

/**
 * Get MIME content type from file extension.
 * @param {string} ext - File extension including dot
 * @returns {string} MIME type
 */
const getContentType = (ext) => {
  const types = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
    '.svg': 'image/svg+xml'
  };
  return types[ext.toLowerCase()] || 'application/octet-stream';
};

export default s3Client;
