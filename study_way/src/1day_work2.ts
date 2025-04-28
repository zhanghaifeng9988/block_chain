import * as crypto from 'crypto';

// 生成公私钥对
function generateKeyPair() {
    return new Promise<{ publicKey: string; privateKey: string }>((resolve, reject) => {
        crypto.generateKeyPair('rsa', {
            modulusLength: 2048, // 密钥长度
            publicKeyEncoding: {
                type: 'spki',
                format: 'pem'
            },
            privateKeyEncoding: {
                type: 'pkcs8',
                format: 'pem'
            }
        }, (err, publicKey, privateKey) => {
            if (err) reject(err);
            else resolve({ publicKey, privateKey });
        });
    });
}


// 用私钥签名
async function signData(privateKey: string, data: string) {
    const signer = crypto.createSign('sha256');
    signer.update(data);
    signer.end();
    const signature = signer.sign(privateKey, 'hex');
    return signature;
}

// 用公钥验证签名
async function verifySignature(publicKey: string, data: string, signature: string) {
    const verifier = crypto.createVerify('sha256');
    verifier.update(data);
    verifier.end();
    const result = verifier.verify(publicKey, signature, 'hex');
    return result;
}

// 主函数
(async () => {
    try {
        // 生成公私钥对
        const { publicKey, privateKey } = await generateKeyPair();
        console.log('Public Key:', publicKey);
        console.log('Private Key:', privateKey);

        // 要签名的数据
        const data = 'nickname + nonce';
        console.log('Data to sign:', data);

        // 用私钥签名
        const signature = await signData(privateKey, data);
        console.log('Signature:', signature);

        // 用公钥验证签名
        const isVerified = await verifySignature(publicKey, data, signature);
        console.log('Verification result:', isVerified);
    } catch (error) {
        console.error('Error:', error);
    }
})();