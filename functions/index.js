const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require('firebase-admin');
const axios = require('axios');
const sharp = require('sharp');
const { setGlobalOptions } = require("firebase-functions/v2");

admin.initializeApp();

setGlobalOptions({
    region: "asia-south1",
    memory: "4GiB",
    timeoutSeconds: 120
});

const storage = admin.storage();
const firestore = admin.firestore();

// Function for uploading "Head to Head" image
// Function for uploading "Head to Head" image and storing the path
exports.uploadHeadToHeadImage = onRequest(async (req, res) => {
  try {
    // Validate request method
    if (req.method !== 'POST') {
      return res.status(405).send('Only POST requests are allowed');
    }

    // Validate request body
    const { matchName, imageData } = req.body;
    if (!matchName || !imageData) {
      return res.status(400).send('Missing required parameters');
    }

    // Convert base64 to buffer
    const originalBuffer = Buffer.from(imageData, 'base64');

    // Compress and optimize the image using Sharp
    const compressedBuffer = await sharp(originalBuffer)
      .jpeg({
        quality: 80,
        chromaSubsampling: '4:4:4',
        force: true
      })
      .resize({
        width: 1200,
        height: 1200,
        fit: 'inside',
        withoutEnlargement: true
      })
      .toBuffer();

    const contentType = 'image/jpeg';
    const fileName = `${matchName}_${Date.now()}.jpg`;
    const imagePath = `match_images/head_to_head/${fileName}`;

    // Upload compressed image to Storage bucket
    const bucket = storage.bucket();
    const file = bucket.file(imagePath);

    await file.save(compressedBuffer, {
      metadata: {
        contentType: contentType,
        cacheControl: 'public, max-age=31536000',
        metadata: {
          originalSize: originalBuffer.length,
          compressedSize: compressedBuffer.length,
          compressionRatio: (originalBuffer.length / compressedBuffer.length).toFixed(2)
        }
      }
    });

    // Get the public URL for the uploaded file
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${imagePath}`;

    // Convert compressed buffer to base64 for Firestore
    const base64Image = `data:${contentType};base64,${compressedBuffer.toString('base64')}`;

    // Update Firestore with base64 string and additional metadata
    const collectionName = 'Fantasy Matches List';
    const docRef = firestore.collection(collectionName).doc(matchName);

    await docRef.update({
      headToHeadTeamImageUrl: base64Image,
      headToHeadTeamImagePublicUrl: publicUrl,
      lastUpdateHeadToHeadTime: new Date().toISOString(),
      imageMetadata: {
        originalSize: originalBuffer.length,
        compressedSize: compressedBuffer.length,
        compressionRatio: (originalBuffer.length / compressedBuffer.length).toFixed(2),
        width: 1200,
        height: 1200,
        contentType: contentType,
        fileName: fileName
      }
    });

    // Send notification to all users
    const message = {
      notification: {
        title: 'New Head To Head Team Added',
        body: `${matchName} Head To Head Free Fantasy Team Added Now. Check The Team Now!`
      },
      topic: 'all_users',
      android: {
        priority: 'high',
        notification: {
          channelId: 'head_to_head_updates'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default'
          }
        }
      }
    };

    try {
      const notificationResponse = await messaging().send(message);
      console.log('Successfully sent notification:', notificationResponse);
    } catch (notificationError) {
      console.error('Error sending notification:', notificationError);
      // Continue execution even if notification fails
    }

    res.status(200).json({
      message: 'Head to head image uploaded and stored successfully',
      publicUrl: publicUrl,
      metadata: {
        originalSize: originalBuffer.length,
        compressedSize: compressedBuffer.length,
        compressionRatio: (originalBuffer.length / compressedBuffer.length).toFixed(2)
      }
    });

  } catch (error) {
    console.error('Error processing head to head image:', error);
    res.status(500).json({
      error: 'Failed to process head to head image',
      message: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});



exports.uploadMegaTeamImage = onRequest(async (req, res) => {
  try {
    // Validate request method
    if (req.method !== 'POST') {
      return res.status(405).send('Only POST requests are allowed');
    }

    // Validate request body
    const { matchName, imageData } = req.body;
    if (!matchName || !imageData) {
      return res.status(400).send('Missing required parameters');
    }

    // Convert base64 to buffer
    const originalBuffer = Buffer.from(imageData, 'base64');

    // Compress and optimize the image using Sharp
    const compressedBuffer = await sharp(originalBuffer)
      .jpeg({
        quality: 85, // Slightly higher quality for mega team images
        chromaSubsampling: '4:4:4',
        force: true
      })
      .resize({
        width: 1500, // Larger max width for mega team images
        height: 1500, // Larger max height for mega team images
        fit: 'inside',
        withoutEnlargement: true
      })
      .toBuffer();

    const contentType = 'image/jpeg';
    const fileName = `${matchName}_mega_${Date.now()}.jpg`;
    const imagePath = `match_images/mega_team/${fileName}`;

    // Upload compressed image to Storage bucket
    const bucket = storage.bucket();
    const file = bucket.file(imagePath);

    await file.save(compressedBuffer, {
      metadata: {
        contentType: contentType,
        cacheControl: 'public, max-age=31536000',
        metadata: {
          originalSize: originalBuffer.length,
          compressedSize: compressedBuffer.length,
          compressionRatio: (originalBuffer.length / compressedBuffer.length).toFixed(2),
          imageType: 'mega_team'
        }
      }
    });

    // Get the public URL for the uploaded file
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${imagePath}`;

    // Convert compressed buffer to base64 for Firestore
    const base64Image = `data:${contentType};base64,${compressedBuffer.toString('base64')}`;

    // Update Firestore with base64 string and additional metadata
    const collectionName = 'Fantasy Matches List';
    const docRef = firestore.collection(collectionName).doc(matchName);

    const updateData = {
      megaTeamImageUrl: base64Image,
      megaTeamImagePublicUrl: publicUrl,
      lastUpdateMegaContestTime: new Date().toISOString(),
      megaTeamImageMetadata: {
        originalSize: originalBuffer.length,
        compressedSize: compressedBuffer.length,
        compressionRatio: (originalBuffer.length / compressedBuffer.length).toFixed(2),
        width: 1500,
        height: 1500,
        contentType: contentType,
        fileName: fileName,
        uploadTimestamp: Date.now()
      }
    };

    // Batch write to ensure atomic update
    const batch = firestore.batch();
    batch.update(docRef, updateData);

    // Add to image history subcollection
    const historyRef = docRef.collection('imageHistory').doc(`mega_${Date.now()}`);
    batch.set(historyRef, {
      type: 'mega_team',
      imageUrl: publicUrl,
      uploadTime: new Date().toISOString(),
      metadata: updateData.megaTeamImageMetadata
    });

    await batch.commit();

    // Send notification to all users
    const message = {
      notification: {
        title: 'New Mega Team Added',
        body: `${matchName} Mega Contest Free Fantasy Team Added Now. Check The Team Now!`
      },
      topic: 'all_users',
      android: {
        priority: 'high',
        notification: {
          channelId: 'mega_team_updates',
          sound: 'default'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            category: 'MEGA_TEAM_UPDATE'
          }
        }
      },
      data: {
        type: 'mega_team',
        matchName: matchName,
        timestamp: Date.now().toString()
      }
    };

    try {
      const notificationResponse = await messaging().send(message);
      console.log('Successfully sent mega team notification:', notificationResponse);
    } catch (notificationError) {
      console.error('Error sending mega team notification:', notificationError);
      // Continue execution even if notification fails
    }

    res.status(200).json({
      message: 'Mega team image uploaded and stored successfully',
      publicUrl: publicUrl,
      metadata: {
        originalSize: originalBuffer.length,
        compressedSize: compressedBuffer.length,
        compressionRatio: (originalBuffer.length / compressedBuffer.length).toFixed(2),
        dimensions: {
          width: 1500,
          height: 1500
        }
      }
    });

  } catch (error) {
    console.error('Error processing mega team image:', error);
    res.status(500).json({
      error: 'Failed to process mega team image',
      message: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined,
      timestamp: new Date().toISOString()
    });
  }
});

// Function to generate a tokenized URL for accessing images
exports.getTokenizedImageUrl = onRequest(async (req, res) => {
  try {
    const { imagePath } = req.query;
    if (!imagePath) {
      return res.status(400).send('Missing required parameter: imagePath');
    }

    const bucket = storage.bucket();
    const file = bucket.file(imagePath);

    const [url] = await file.getSignedUrl({
      action: 'read',
      expires: '03-01-2500', // Adjust the expiration date as needed
    });

    res.status(200).json({ tokenizedUrl: url });
  } catch (error) {
    console.error('Error generating tokenized URL:', error);
    res.status(500).send(`Failed to generate tokenized URL: ${error.message}`);
  }
});

// Function to get current time in IST
function getCurrentISTTime() {
    const now = new Date();
    now.setHours(now.getHours() + 5);
    now.setMinutes(now.getMinutes() + 30);
    return now.toISOString();
}

// Parse match time to milliseconds for proper sorting and comparison
function parseMatchTime(timeString) {
    let totalMilliseconds = 0;

    if (timeString.includes('d')) {
        const days = parseInt(timeString.split('d')[0]);
        totalMilliseconds += days * 24 * 60 * 60 * 1000;
        timeString = timeString.split('d')[1].trim();
    }

    if (timeString.includes('h')) {
        const hours = parseInt(timeString.split('h')[0]);
        totalMilliseconds += hours * 60 * 60 * 1000;
        timeString = timeString.split('h')[1].trim();
    }

    if (timeString.includes('m')) {
        const minutes = parseInt(timeString.split('m')[0]);
        totalMilliseconds += minutes * 60 * 1000;
        timeString = timeString.split('m')[1].trim();
    }

    if (timeString.includes('s')) {
        const seconds = parseInt(timeString.split('s')[0]);
        totalMilliseconds += seconds * 1000;
    }

    return totalMilliseconds;
}

async function isSchedulerEnabled() {
    const db = admin.firestore();
    const configDoc = await db.collection('Settings').doc('config').get();
    if (!configDoc.exists) {
        await db.collection('Settings').doc('config').set({
            schedulerEnabled: true,
            startedAt: getCurrentISTTime(),
            lastUpdated: getCurrentISTTime()
        });
        return true;
    }
    return configDoc.data().schedulerEnabled;
}

async function updateMatches() {
    const db = admin.firestore();

    try {
        if (!(await isSchedulerEnabled())) {
            console.log('Scheduler is disabled. Skipping update.');
            return { success: false, message: 'Scheduler is disabled' };
        }

        const response = await axios.post(
            'https://fantasy-scraper-63646434248.asia-south1.run.app'
        );

        const apiData = response.data;

        if (apiData.status !== 200) {
            throw new Error('API request failed');
        }

        // Sort matches by match time
        apiData.data.sort((a, b) => {
            const timeA = parseMatchTime(a.matchTime);
            const timeB = parseMatchTime(b.matchTime);
            return timeA - timeB;
        });

        // Update Settings collection with latest data
        const settingsRef = db.collection('Settings').doc('settings');
        const configRef = db.collection('Settings').doc('config');
        const settingsDoc = await settingsRef.get();

        const batch = db.batch();

        if (!settingsDoc.exists ||
            JSON.stringify(settingsDoc.data()?.latestData) !== JSON.stringify(apiData.data)) {

            batch.set(settingsRef, {
                latestData: apiData.data,
                lastUpdated: getCurrentISTTime()
            }, { merge: true });

            batch.update(configRef, {
                lastUpdated: getCurrentISTTime()
            });
        }

        // Process matches
        const fantasyMatchesRef = db.collection('Fantasy Matches List');
        const currentMatchNames = new Set(apiData.data.map(match =>
            `${match.teams.team1.name} vs ${match.teams.team2.name}`
        ));

        // Get all existing matches
        const existingMatches = await fantasyMatchesRef.get();
        const existingMatchDocs = new Map();

        existingMatches.forEach(doc => {
            existingMatchDocs.set(doc.id, doc.data());
        });

        // Process new matches and updates
        for (const match of apiData.data) {
            const matchName = `${match.teams.team1.name} vs ${match.teams.team2.name}`;
            const matchRef = fantasyMatchesRef.doc(matchName);

            const matchData = {
                tournament: match.tournament,
                team1Name: match.teams.team1.name,
                team2Name: match.teams.team2.name,
                team1Code: match.teams.team1.code,
                team2Code: match.teams.team2.code,
                team1Flag: match.teams.team1.flagUrl,
                team2Flag: match.teams.team2.flagUrl,
                isMatchStarted: false,
//                headToHeadTeamImageUrl: '',
//                lastUpdateMegaContestTime: '',
//                lastUpdateHeadToHeadTime: '',
//                megaTeamImageUrl: '',
                matchTime: match.matchTime,
                sortTime: parseMatchTime(match.matchTime),
                lastUpdated: getCurrentISTTime()
            };

            if (!existingMatchDocs.has(matchName)) {
                batch.set(matchRef, matchData);
            } else {
                // Update only if match time or other critical data has changed
                const existingData = existingMatchDocs.get(matchName);
                if (existingData.matchTime !== match.matchTime ||
                    existingData.tournament !== match.tournament) {
                    batch.update(matchRef, matchData);
                }
            }
        }

        // Mark finished matches
        for (const [matchName, matchData] of existingMatchDocs) {
            if (!currentMatchNames.has(matchName)) {
                batch.update(fantasyMatchesRef.doc(matchName), {
                    isMatchStarted: true,
                                    headToHeadTeamImageUrl: '',
                                    lastUpdateMegaContestTime: '',
                                    lastUpdateHeadToHeadTime: '',
                                    megaTeamImageUrl: '',
                    lastUpdated: getCurrentISTTime()
                });
            }
        }

        // Commit all changes in one batch
        await batch.commit();

        console.log('Fantasy matches updated successfully');
        return {
            success: true,
            message: 'Fantasy matches updated successfully',
            updatedAt: getCurrentISTTime()
        };

    } catch (error) {
        console.error('Error updating fantasy matches:', error);
        throw error;
    }
}

// Scheduled function that runs every 15 minutes
exports.updateFantasyMatches = onSchedule("*/15 * * * *", async (event) => {
    return await updateMatches();
});

// HTTP endpoint for manual testing
exports.manualUpdateFantasyMatches = onRequest(async (req, res) => {
    try {
        const result = await updateMatches();
        res.json(result);
    } catch (error) {
        res.status(500).json({
            error: error.message,
            timestamp: getCurrentISTTime()
        });
    }
});

// Function to stop the scheduler
exports.stopScheduler = onRequest(async (req, res) => {
    try {
        const db = admin.firestore();
        const currentTime = getCurrentISTTime();

        await db.collection('Settings').doc('config').set({
            schedulerEnabled: false,
            stoppedAt: currentTime,
            lastUpdated: currentTime,
            stoppedBy: req.headers['x-forwarded-for'] || req.connection.remoteAddress
        }, { merge: true });

        res.json({
            success: true,
            message: 'Scheduler stopped successfully',
            stoppedAt: currentTime
        });
    } catch (error) {
        res.status(500).json({
            error: error.message,
            timestamp: getCurrentISTTime()
        });
    }
});

// Function to start the scheduler
exports.startScheduler = onRequest(async (req, res) => {
    try {
        const db = admin.firestore();
        const currentTime = getCurrentISTTime();

        await db.collection('Settings').doc('config').set({
            schedulerEnabled: true,
            startedAt: currentTime,
            lastUpdated: currentTime,
            startedBy: req.headers['x-forwarded-for'] || req.connection.remoteAddress
        }, { merge: true });

        // Trigger an immediate update when starting
        const updateResult = await updateMatches();

        res.json({
            success: true,
            message: 'Scheduler started successfully',
            startedAt: currentTime,
            updateResult
        });
    } catch (error) {
        res.status(500).json({
            error: error.message,
            timestamp: getCurrentISTTime()
        });
    }
});

// Function to get scheduler status with detailed metrics
exports.getSchedulerStatus = onRequest(async (req, res) => {
    try {
        const db = admin.firestore();
        const configDoc = await db.collection('Settings').doc('config').get();
        const settingsDoc = await db.collection('Settings').doc('settings').get();

        if (!configDoc.exists) {
            const currentTime = getCurrentISTTime();
            return res.json({
                enabled: true,
                message: 'Scheduler is running (default state)',
                startedAt: currentTime,
                lastUpdated: currentTime,
                matchesCount: 0
            });
        }

        const config = configDoc.data();
        const settings = settingsDoc.exists ? settingsDoc.data() : {};
        const matchesCount = settings.latestData?.length || 0;

        res.json({
            enabled: config.schedulerEnabled,
            message: config.schedulerEnabled ? 'Scheduler is running' : 'Scheduler is stopped',
            lastUpdated: config.lastUpdated,
            startedAt: config.startedAt,
            stoppedAt: config.stoppedAt,
            matchesCount,
            latestUpdateStatus: settings.latestUpdateStatus || 'unknown',
            metrics: {
                activeMatches: matchesCount,
                lastSuccessfulUpdate: config.lastUpdated,
                uptime: config.schedulerEnabled ?
                    Date.parse(getCurrentISTTime()) - Date.parse(config.startedAt) : 0
            }
        });
    } catch (error) {
        res.status(500).json({
            error: error.message,
            timestamp: getCurrentISTTime()
        });
    }
});


