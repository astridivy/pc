const crypto = require('crypto');

function generateCode(byteCount) {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-$';
    let result = '';
    // Ensure we generate a multiple of 3 bytes
    const buf = crypto.randomBytes(byteCount);

    const usableBytes = byteCount - (byteCount % 3)
    for (let i = 0; i < usableBytes; i += 3) {
        // Combine 3 bytes into a 24-bit number
        const chunk = (buf[i] << 16) + (buf[i + 1] << 8) + buf[i + 2];
        // Extract and map 4 6-bit values from the 24-bit chunk
        for (let j = 0; j < 4; j++) {
            const index = (chunk >> j) & 0x3F; // Shift right and mask out the 6 bits
            result += characters.charAt(index);
        }
    }

    return result; // Adjust the result to the desired length
}

module.exports = generateCode
