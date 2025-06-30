// Asteroids Game - JavaScript Implementation with Sound Effects
class SoundSystem {
    constructor() {
        this.audioContext = null;
        this.sirenOscillator = null;
        this.sirenGain = null;
        this.soundEnabled = false; // Start with sound OFF due to browser policies
        this.audioInitialized = false;
        this.initAudio();
    }
    
    initAudio() {
        try {
            this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            console.log('Audio context created, state:', this.audioContext.state);
        } catch (e) {
            console.log('Web Audio API not supported');
        }
    }
    
    async enableAudio() {
        if (!this.audioContext) return false;
        
        try {
            if (this.audioContext.state === 'suspended') {
                await this.audioContext.resume();
                console.log('Audio context resumed, state:', this.audioContext.state);
            }
            this.audioInitialized = true;
            this.soundEnabled = true;
            return true;
        } catch (e) {
            console.error('Failed to enable audio:', e);
            return false;
        }
    }
    
    toggleSound() {
        if (!this.audioInitialized) {
            // First time - need to enable audio
            this.enableAudio().then(success => {
                if (success) {
                    console.log('Audio enabled for first time');
                    // Update button will be called by the click handler
                } else {
                    console.error('Failed to enable audio');
                }
            });
            return this.soundEnabled;
        } else {
            // Already initialized, just toggle
            this.soundEnabled = !this.soundEnabled;
            console.log('Sound toggled to:', this.soundEnabled);
            return this.soundEnabled;
        }
    }
    
    isSoundEnabled() {
        return this.soundEnabled && this.audioInitialized;
    }
    
    playThrustSound() {
        if (!this.audioContext || !this.soundEnabled || !this.audioInitialized) return;
        
        const oscillator = this.audioContext.createOscillator();
        const gainNode = this.audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(this.audioContext.destination);
        
        oscillator.frequency.setValueAtTime(80, this.audioContext.currentTime);
        oscillator.frequency.exponentialRampToValueAtTime(40, this.audioContext.currentTime + 0.1);
        
        gainNode.gain.setValueAtTime(0.1, this.audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.1);
        
        oscillator.type = 'sawtooth';
        oscillator.start(this.audioContext.currentTime);
        oscillator.stop(this.audioContext.currentTime + 0.1);
    }
    
    playShootSound() {
        if (!this.audioContext || !this.soundEnabled || !this.audioInitialized) return;
        
        const oscillator = this.audioContext.createOscillator();
        const gainNode = this.audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(this.audioContext.destination);
        
        oscillator.frequency.setValueAtTime(800, this.audioContext.currentTime);
        oscillator.frequency.exponentialRampToValueAtTime(400, this.audioContext.currentTime + 0.1);
        
        gainNode.gain.setValueAtTime(0.2, this.audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.1);
        
        oscillator.type = 'square';
        oscillator.start(this.audioContext.currentTime);
        oscillator.stop(this.audioContext.currentTime + 0.1);
    }
    
    playExplosionSound() {
        if (!this.audioContext || !this.soundEnabled || !this.audioInitialized) return;
        
        // Create noise for explosion
        const bufferSize = this.audioContext.sampleRate * 0.5;
        const buffer = this.audioContext.createBuffer(1, bufferSize, this.audioContext.sampleRate);
        const data = buffer.getChannelData(0);
        
        for (let i = 0; i < bufferSize; i++) {
            data[i] = Math.random() * 2 - 1;
        }
        
        const noise = this.audioContext.createBufferSource();
        const gainNode = this.audioContext.createGain();
        const filter = this.audioContext.createBiquadFilter();
        
        noise.buffer = buffer;
        noise.connect(filter);
        filter.connect(gainNode);
        gainNode.connect(this.audioContext.destination);
        
        filter.type = 'lowpass';
        filter.frequency.setValueAtTime(1000, this.audioContext.currentTime);
        filter.frequency.exponentialRampToValueAtTime(100, this.audioContext.currentTime + 0.5);
        
        gainNode.gain.setValueAtTime(0.3, this.audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.5);
        
        noise.start(this.audioContext.currentTime);
        noise.stop(this.audioContext.currentTime + 0.5);
    }
    
    playUFOSound() {
        if (!this.audioContext || !this.soundEnabled || !this.audioInitialized) return;
        
        const oscillator = this.audioContext.createOscillator();
        const gainNode = this.audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(this.audioContext.destination);
        
        oscillator.frequency.setValueAtTime(200, this.audioContext.currentTime);
        oscillator.frequency.setValueAtTime(300, this.audioContext.currentTime + 0.1);
        oscillator.frequency.setValueAtTime(200, this.audioContext.currentTime + 0.2);
        
        gainNode.gain.setValueAtTime(0.15, this.audioContext.currentTime);
        gainNode.gain.setValueAtTime(0.15, this.audioContext.currentTime + 0.2);
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.3);
        
        oscillator.type = 'sine';
        oscillator.start(this.audioContext.currentTime);
        oscillator.stop(this.audioContext.currentTime + 0.3);
    }
    
    playHyperspaceSound() {
        if (!this.audioContext || !this.soundEnabled || !this.audioInitialized) return;
        
        const oscillator = this.audioContext.createOscillator();
        const gainNode = this.audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(this.audioContext.destination);
        
        oscillator.frequency.setValueAtTime(1000, this.audioContext.currentTime);
        oscillator.frequency.exponentialRampToValueAtTime(100, this.audioContext.currentTime + 0.3);
        
        gainNode.gain.setValueAtTime(0.2, this.audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.3);
        
        oscillator.type = 'sawtooth';
        oscillator.start(this.audioContext.currentTime);
        oscillator.stop(this.audioContext.currentTime + 0.3);
    }
    
    playShipCrashSound() {
        if (!this.audioContext || !this.soundEnabled || !this.audioInitialized) return;
        
        // Create a realistic crash sound with multiple components
        // Component 1: Initial impact (sharp metallic crash)
        const crash1 = this.audioContext.createOscillator();
        const crash1Gain = this.audioContext.createGain();
        crash1.connect(crash1Gain);
        crash1Gain.connect(this.audioContext.destination);
        
        crash1.frequency.setValueAtTime(800, this.audioContext.currentTime);
        crash1.frequency.exponentialRampToValueAtTime(200, this.audioContext.currentTime + 0.2);
        crash1Gain.gain.setValueAtTime(0.4, this.audioContext.currentTime);
        crash1Gain.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.2);
        crash1.type = 'square';
        
        // Component 2: Metal scraping/grinding
        const crash2 = this.audioContext.createOscillator();
        const crash2Gain = this.audioContext.createGain();
        crash2.connect(crash2Gain);
        crash2Gain.connect(this.audioContext.destination);
        
        crash2.frequency.setValueAtTime(150, this.audioContext.currentTime + 0.1);
        crash2.frequency.exponentialRampToValueAtTime(80, this.audioContext.currentTime + 0.6);
        crash2Gain.gain.setValueAtTime(0.3, this.audioContext.currentTime + 0.1);
        crash2Gain.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.6);
        crash2.type = 'sawtooth';
        
        // Component 3: Debris/rumble (low frequency)
        const crash3 = this.audioContext.createOscillator();
        const crash3Gain = this.audioContext.createGain();
        crash3.connect(crash3Gain);
        crash3Gain.connect(this.audioContext.destination);
        
        crash3.frequency.setValueAtTime(60, this.audioContext.currentTime + 0.05);
        crash3.frequency.exponentialRampToValueAtTime(30, this.audioContext.currentTime + 0.8);
        crash3Gain.gain.setValueAtTime(0.35, this.audioContext.currentTime + 0.05);
        crash3Gain.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.8);
        crash3.type = 'triangle';
        
        // Start all components
        crash1.start(this.audioContext.currentTime);
        crash2.start(this.audioContext.currentTime + 0.1);
        crash3.start(this.audioContext.currentTime + 0.05);
        
        // Stop all components
        crash1.stop(this.audioContext.currentTime + 0.2);
        crash2.stop(this.audioContext.currentTime + 0.6);
        crash3.stop(this.audioContext.currentTime + 0.8);
    }
    
    playAsteroidBreakSound() {
        if (!this.audioContext || !this.soundEnabled || !this.audioInitialized) return;
        
        // Create boulder breaking sound with multiple frequencies
        const oscillator1 = this.audioContext.createOscillator();
        const oscillator2 = this.audioContext.createOscillator();
        const oscillator3 = this.audioContext.createOscillator();
        const gainNode = this.audioContext.createGain();
        
        oscillator1.connect(gainNode);
        oscillator2.connect(gainNode);
        oscillator3.connect(gainNode);
        gainNode.connect(this.audioContext.destination);
        
        // Different frequencies for rock breaking effect
        oscillator1.frequency.setValueAtTime(200, this.audioContext.currentTime);
        oscillator1.frequency.exponentialRampToValueAtTime(80, this.audioContext.currentTime + 0.3);
        oscillator2.frequency.setValueAtTime(350, this.audioContext.currentTime);
        oscillator2.frequency.exponentialRampToValueAtTime(120, this.audioContext.currentTime + 0.3);
        oscillator3.frequency.setValueAtTime(500, this.audioContext.currentTime);
        oscillator3.frequency.exponentialRampToValueAtTime(180, this.audioContext.currentTime + 0.3);
        
        gainNode.gain.setValueAtTime(0.3, this.audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.3);
        
        oscillator1.type = 'sawtooth';
        oscillator2.type = 'square';
        oscillator3.type = 'triangle';
        
        oscillator1.start(this.audioContext.currentTime);
        oscillator2.start(this.audioContext.currentTime);
        oscillator3.start(this.audioContext.currentTime);
        oscillator1.stop(this.audioContext.currentTime + 0.3);
        oscillator2.stop(this.audioContext.currentTime + 0.3);
        oscillator3.stop(this.audioContext.currentTime + 0.3);
    }
    
    playUFOHitSound() {
        if (!this.audioContext || !this.soundEnabled || !this.audioInitialized) return;
        
        // Metallic UFO destruction sound
        const oscillator1 = this.audioContext.createOscillator();
        const oscillator2 = this.audioContext.createOscillator();
        const gainNode = this.audioContext.createGain();
        
        oscillator1.connect(gainNode);
        oscillator2.connect(gainNode);
        gainNode.connect(this.audioContext.destination);
        
        oscillator1.frequency.setValueAtTime(800, this.audioContext.currentTime);
        oscillator1.frequency.exponentialRampToValueAtTime(200, this.audioContext.currentTime + 0.4);
        oscillator2.frequency.setValueAtTime(1200, this.audioContext.currentTime);
        oscillator2.frequency.exponentialRampToValueAtTime(300, this.audioContext.currentTime + 0.4);
        
        gainNode.gain.setValueAtTime(0.35, this.audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.4);
        
        oscillator1.type = 'square';
        oscillator2.type = 'sawtooth';
        oscillator1.start(this.audioContext.currentTime);
        oscillator2.start(this.audioContext.currentTime);
        oscillator1.stop(this.audioContext.currentTime + 0.4);
        oscillator2.stop(this.audioContext.currentTime + 0.4);
    }
    
    startSirenSound() {
        if (!this.audioContext || this.sirenOscillator || !this.soundEnabled || !this.audioInitialized) return;
        
        this.sirenOscillator = this.audioContext.createOscillator();
        this.sirenGain = this.audioContext.createGain();
        
        this.sirenOscillator.connect(this.sirenGain);
        this.sirenGain.connect(this.audioContext.destination);
        
        // Create warning siren effect
        this.sirenOscillator.frequency.setValueAtTime(400, this.audioContext.currentTime);
        this.sirenGain.gain.setValueAtTime(0.05, this.audioContext.currentTime);
        
        this.sirenOscillator.type = 'sine';
        this.sirenOscillator.start(this.audioContext.currentTime);
        
        // Modulate frequency for siren effect
        this.modulateSiren();
    }
    
    modulateSiren() {
        if (!this.sirenOscillator) return;
        
        const now = this.audioContext.currentTime;
        this.sirenOscillator.frequency.setValueAtTime(400, now);
        this.sirenOscillator.frequency.linearRampToValueAtTime(600, now + 0.5);
        this.sirenOscillator.frequency.linearRampToValueAtTime(400, now + 1.0);
        
        // Continue modulation
        setTimeout(() => {
            if (this.sirenOscillator) {
                this.modulateSiren();
            }
        }, 1000);
    }
    
    stopSirenSound() {
        if (this.sirenOscillator) {
            try {
                this.sirenOscillator.stop();
            } catch (e) {
                // Oscillator might already be stopped
            }
            this.sirenOscillator = null;
            this.sirenGain = null;
        }
    }
    
    isSirenPlaying() {
        return this.sirenOscillator !== null;
    }
}

class Game {
    constructor() {
        this.canvas = document.getElementById('gameCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.width = this.canvas.width;
        this.height = this.canvas.height;
        
        this.score = 0;
        this.lives = 3;
        this.gameRunning = true;
        this.level = 1;
        this.levelDisplayTimer = 0;
        this.showLevelDisplay = false;
        this.respawnDelay = 0; // Frames to wait before respawning
        this.respawnDelayTime = 180; // 3 seconds at 60fps
        this.gameState = 'playing'; // 'playing', 'gameOver', 'highScore', 'showingScores'
        this.highScores = [];
        this.playerInitials = '';
        this.initialsInput = 0; // 0-2 for which letter we're entering
        
        this.ship = new Ship(this.width / 2, this.height / 2);
        this.asteroids = [];
        this.bullets = [];
        this.particles = [];
        this.ufos = [];
        this.ufoSpawnTimer = 0;
        this.ufoSpawnDelay = 600; // Spawn UFO every 10 seconds (at 60fps)
        
        this.keys = {};
        this.soundSystem = new SoundSystem();
        
        this.initializeLevel();
        this.setupEventListeners();
        
        // Load high scores and show them initially
        this.loadHighScores().then(() => {
            this.gameState = 'showingScores';
        });
        
        // Focus the canvas so keyboard controls work immediately
        setTimeout(() => {
            this.canvas.focus();
            console.log('Game canvas focused for keyboard controls');
        }, 100);
        
        this.gameLoop();
    }
    
    detectMobile() {
        // Force mobile detection for common mobile patterns
        const userAgent = navigator.userAgent.toLowerCase();
        
        // Check for mobile keywords
        const mobileKeywords = [
            'android', 'webos', 'iphone', 'ipad', 'ipod', 'blackberry', 
            'iemobile', 'opera mini', 'mobile', 'tablet', 'pixel', 
            'samsung', 'lg', 'htc', 'motorola', 'nokia', 'sony'
        ];
        
        const hasMobileKeyword = mobileKeywords.some(keyword => userAgent.includes(keyword));
        
        // Check touch capability
        const hasTouchSupport = 'ontouchstart' in window || 
                               navigator.maxTouchPoints > 0 || 
                               navigator.msMaxTouchPoints > 0;
        
        // Check screen size (mobile screens are typically smaller)
        const hasSmallScreen = window.screen.width <= 768 || 
                              window.screen.height <= 768 ||
                              window.innerWidth <= 768;
        
        // Check for mobile-specific features
        const hasMobileFeatures = 'orientation' in window || 
                                 typeof window.DeviceMotionEvent !== 'undefined';
        
        const isMobile = hasMobileKeyword || hasTouchSupport || hasSmallScreen || hasMobileFeatures;
        
        // Force mobile for debugging - remove this line later
        // const isMobile = true;
        
        console.log('=== MOBILE DETECTION DEBUG ===');
        console.log('User Agent:', userAgent);
        console.log('Has Mobile Keyword:', hasMobileKeyword);
        console.log('Has Touch Support:', hasTouchSupport);
        console.log('Has Small Screen:', hasSmallScreen);
        console.log('Screen Size:', window.screen.width, 'x', window.screen.height);
        console.log('Window Size:', window.innerWidth, 'x', window.innerHeight);
        console.log('Max Touch Points:', navigator.maxTouchPoints);
        console.log('Has Mobile Features:', hasMobileFeatures);
        console.log('FINAL RESULT - Is Mobile:', isMobile);
        console.log('===============================');
        
        return isMobile;
    }
    
    setupCanvas() {
        console.log('=== SETUP CANVAS DEBUG ===');
        console.log('setupCanvas called, isMobile:', this.isMobile);
        
        if (this.isMobile) {
            // Get actual screen dimensions
            const screenWidth = window.innerWidth;
            const screenHeight = window.innerHeight;
            this.isPortrait = screenHeight > screenWidth;
            
            console.log('Mobile detected - Screen:', screenWidth, 'x', screenHeight, 'Portrait:', this.isPortrait);
            
            // Set canvas to fill most of the screen
            if (this.isPortrait) {
                // Portrait: tall rectangle
                this.canvas.width = Math.min(screenWidth - 20, 400);
                this.canvas.height = Math.min(screenHeight - 120, 700); // Leave space for UI
            } else {
                // Landscape: wide rectangle  
                this.canvas.width = Math.min(screenWidth - 20, 700);
                this.canvas.height = Math.min(screenHeight - 80, 400); // Leave space for UI
            }
            
            console.log('Canvas size set to:', this.canvas.width, 'x', this.canvas.height);
            
            // Force mobile controls to show
            this.showMobileControls();
            
        } else {
            console.log('Desktop detected');
            // Desktop canvas size
            this.canvas.width = 800;
            this.canvas.height = 600;
            
            // Show desktop controls
            this.showDesktopControls();
        }
        console.log('=========================');
    }
    
    showMobileControls() {
        console.log('Attempting to show mobile controls...');
        
        // Try multiple times to ensure DOM is ready
        const attemptShowControls = () => {
            const mobileControls = document.getElementById('mobileControls');
            const desktopControls = document.getElementById('desktopControls');
            
            console.log('Mobile controls element:', mobileControls);
            console.log('Desktop controls element:', desktopControls);
            
            if (mobileControls && desktopControls) {
                mobileControls.style.display = 'block';
                desktopControls.style.display = 'none';
                console.log('✅ Mobile controls shown, desktop controls hidden');
                return true;
            } else {
                console.log('❌ Control elements not found, retrying...');
                return false;
            }
        };
        
        // Try immediately
        if (!attemptShowControls()) {
            // Try again after a short delay
            setTimeout(() => {
                if (!attemptShowControls()) {
                    // Try one more time after DOM is definitely ready
                    setTimeout(attemptShowControls, 500);
                }
            }, 100);
        }
    }
    
    showDesktopControls() {
        const mobileControls = document.getElementById('mobileControls');
        const desktopControls = document.getElementById('desktopControls');
        
        if (mobileControls && desktopControls) {
            mobileControls.style.display = 'none';
            desktopControls.style.display = 'block';
            console.log('Desktop controls shown, mobile controls hidden');
        }
    }
    
    setupOrientationChange() {
        if (this.isMobile) {
            window.addEventListener('orientationchange', () => {
                setTimeout(() => {
                    this.setupCanvas();
                    this.width = this.canvas.width;
                    this.height = this.canvas.height;
                    // Reposition ship to center of new canvas
                    this.ship.x = this.width / 2;
                    this.ship.y = this.height / 2;
                }, 100);
            });
            
            window.addEventListener('resize', () => {
                if (this.isMobile) {
                    this.setupCanvas();
                    this.width = this.canvas.width;
                    this.height = this.canvas.height;
                    // Reposition ship to center of new canvas
                    this.ship.x = this.width / 2;
                    this.ship.y = this.height / 2;
                }
            });
        }
    }
    
    initializeLevel() {
        // Clear existing asteroids
        this.asteroids = [];
        
        // Show level display for 1 second
        this.showLevelDisplay = true;
        this.levelDisplayTimer = 60; // 1 second at 60fps
        
        // Determine number of asteroids based on level
        let asteroidCount;
        let speedMultiplier;
        
        switch(this.level) {
            case 1:
                asteroidCount = 2;
                speedMultiplier = 1.0;
                break;
            case 2:
                asteroidCount = 3;
                speedMultiplier = 1.2;
                break;
            case 3:
                asteroidCount = 4;
                speedMultiplier = 1.4;
                break;
            default: // Level 4 and up
                asteroidCount = 4;
                speedMultiplier = 1.4;
                break;
        }
        
        // Create asteroids for this level
        for (let i = 0; i < asteroidCount; i++) {
            let x, y;
            do {
                x = Math.random() * this.width;
                y = Math.random() * this.height;
            } while (this.distanceTo(x, y, this.ship.x, this.ship.y) < 100);
            
            const asteroid = new Asteroid(x, y, 'large');
            // Apply speed multiplier
            asteroid.velocity.x *= speedMultiplier;
            asteroid.velocity.y *= speedMultiplier;
            this.asteroids.push(asteroid);
        }
    }
    
    setupEventListeners() {
        document.addEventListener('keydown', (e) => {
            // Multiple layers of protection against sound button interference
            if (document.activeElement && document.activeElement.id === 'soundToggle') {
                console.log('Keydown blocked - sound button focused');
                return;
            }
            if (e.target && e.target.id === 'soundToggle') {
                console.log('Keydown blocked - sound button target');
                return;
            }
            // Additional check for any element with sound-related ID
            if (document.activeElement && document.activeElement.id && document.activeElement.id.includes('sound')) {
                console.log('Keydown blocked - sound-related element focused');
                return;
            }
            
            // Handle different game states
            if (this.gameState === 'showingScores') {
                if (e.code === 'Space') {
                    this.gameState = 'playing';
                    this.resetGame();
                }
                return;
            }
            
            if (this.gameState === 'highScore') {
                this.handleInitialsInput(e);
                return;
            }
            
            if (this.gameState === 'gameOver') {
                if (e.code === 'Space') {
                    this.gameState = 'showingScores';
                }
                return;
            }
            
            // Normal game controls
            if (this.gameState === 'playing') {
                this.keys[e.code] = true;
            }
        });
        
        document.addEventListener('keyup', (e) => {
            // Multiple layers of protection against sound button interference
            if (document.activeElement && document.activeElement.id === 'soundToggle') {
                console.log('Keyup blocked - sound button focused');
                return;
            }
            if (e.target && e.target.id === 'soundToggle') {
                console.log('Keyup blocked - sound button target');
                return;
            }
            // Additional check for any element with sound-related ID
            if (document.activeElement && document.activeElement.id && document.activeElement.id.includes('sound')) {
                console.log('Keyup blocked - sound-related element focused');
                return;
            }
            
            // Only handle keyup for playing state
            if (this.gameState === 'playing') {
                this.keys[e.code] = false;
            }
        });
        
        // Ensure canvas gets focus when clicked
        this.canvas.addEventListener('click', () => {
            this.canvas.focus();
            console.log('Canvas clicked and focused');
        });
        
        // Set up sound toggle button with more robust event handling
        this.setupSoundToggle();
    }
    
    setupSoundToggle() {
        // Use a more robust approach to find and set up the sound toggle
        const setupButton = () => {
            const soundToggle = document.getElementById('soundToggle');
            if (soundToggle) {
                console.log('Setting up sound toggle button...');
                
                // Remove any existing listeners by cloning the button
                const newSoundToggle = soundToggle.cloneNode(true);
                soundToggle.parentNode.replaceChild(newSoundToggle, soundToggle);
                
                // Add ONLY mousedown/mouseup handlers - completely ignore keyboard
                newSoundToggle.addEventListener('mousedown', (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    e.stopImmediatePropagation();
                    // Don't do anything on mousedown, just prevent defaults
                });
                
                newSoundToggle.addEventListener('mouseup', async (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    e.stopImmediatePropagation();
                    
                    console.log('Sound toggle clicked with mouse (mouseup)!');
                    
                    if (!this.soundSystem.audioInitialized) {
                        console.log('First click - enabling audio...');
                        const success = await this.soundSystem.enableAudio();
                        if (success) {
                            this.updateSoundToggleButton(true);
                            console.log('Audio enabled successfully');
                        } else {
                            console.error('Failed to enable audio');
                        }
                    } else {
                        console.log('Toggling sound...');
                        const soundEnabled = this.soundSystem.toggleSound();
                        this.updateSoundToggleButton(soundEnabled);
                    }
                    
                    // Return focus to the game canvas immediately
                    setTimeout(() => {
                        this.canvas.focus();
                        console.log('Focus returned to game canvas');
                    }, 50);
                });
                
                // Block ALL keyboard events on the button
                newSoundToggle.addEventListener('keydown', (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    e.stopImmediatePropagation();
                    console.log('Keyboard event blocked on sound button');
                });
                
                newSoundToggle.addEventListener('keyup', (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    e.stopImmediatePropagation();
                    console.log('Keyboard event blocked on sound button');
                });
                
                newSoundToggle.addEventListener('keypress', (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    e.stopImmediatePropagation();
                    console.log('Keyboard event blocked on sound button');
                });
                
                // Block click events (which can be triggered by keyboard)
                newSoundToggle.addEventListener('click', (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    e.stopImmediatePropagation();
                    console.log('Click event blocked - using mouseup instead');
                });
                
                // Prevent the button from getting focus at all
                newSoundToggle.addEventListener('focus', (e) => {
                    e.target.blur();
                    this.canvas.focus();
                    console.log('Button focus prevented, canvas focused');
                });
                
                // Initialize button state (starts muted due to browser policy)
                this.updateSoundToggleButton(false);
                console.log('Sound toggle button set up successfully');
            } else {
                console.error('Sound toggle button not found');
                // Try again after a short delay
                setTimeout(setupButton, 100);
            }
        };
        
        // Set up the button
        setupButton();
    }
    
    updateSoundToggleButton(soundEnabled) {
        const soundToggle = document.getElementById('soundToggle');
        console.log('Updating button - soundEnabled:', soundEnabled, 'button found:', !!soundToggle);
        if (soundToggle) {
            if (soundEnabled) {
                soundToggle.textContent = '🔊';
                soundToggle.classList.remove('muted');
                soundToggle.title = 'Mute Sound';
                console.log('Button set to sound ON');
            } else {
                soundToggle.textContent = '🔇';
                soundToggle.classList.add('muted');
                soundToggle.title = 'Enable Sound (Click to activate audio)';
                console.log('Button set to sound OFF');
            }
        } else {
            console.error('Sound toggle button not found in updateSoundToggleButton');
        }
    }
    
    // High Score System Methods
    async loadHighScores() {
        try {
            console.log('Loading high scores...');
            const response = await fetch('/api/highscores');
            if (response.ok) {
                this.highScores = await response.json();
                console.log('High scores loaded:', this.highScores.length, 'scores');
                console.log('High scores data:', this.highScores);
            } else {
                console.log('No high scores found, starting fresh');
                this.highScores = [];
            }
        } catch (error) {
            console.error('Error loading high scores:', error);
            this.highScores = [];
        }
    }
    
    async saveHighScore(initials, score) {
        try {
            console.log('Saving high score:', initials, score);
            const response = await fetch('/api/highscores', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ initials, score })
            });
            if (response.ok) {
                console.log('High score saved successfully');
                await this.loadHighScores(); // Reload to get updated list
                return true;
            } else {
                console.error('Failed to save high score:', response.status, response.statusText);
            }
        } catch (error) {
            console.error('Error saving high score:', error);
        }
        return false;
    }
    
    isHighScore(score) {
        // Any score above 0 qualifies if we have less than 20 scores
        if (score <= 0) return false;
        if (this.highScores.length < 20) return true;
        // If we have 20 scores, check if this score beats the lowest (20th place)
        return score > this.highScores[this.highScores.length - 1].score;
    }
    
    drawHighScores() {
        this.ctx.fillStyle = 'white';
        this.ctx.font = '48px Courier New';
        this.ctx.textAlign = 'center';
        this.ctx.fillText('HIGH SCORES', this.width / 2, 80);
        
        this.ctx.font = '24px Courier New';
        this.ctx.textAlign = 'left';
        
        const startY = 140;
        const lineHeight = 25;
        
        if (this.highScores.length === 0) {
            this.ctx.textAlign = 'center';
            this.ctx.fillStyle = '#888';
            this.ctx.fillText('No scores yet - be the first!', this.width / 2, startY + 100);
            this.ctx.fillStyle = 'white';
        } else {
            for (let i = 0; i < Math.min(this.highScores.length, 20); i++) {
                const score = this.highScores[i];
                const rank = (i + 1).toString().padStart(2, ' ');
                const initials = score.initials.padEnd(3, ' ');
                const points = score.score.toString().padStart(8, ' ');
                
                this.ctx.fillText(`${rank}. ${initials} ${points}`, this.width / 2 - 150, startY + i * lineHeight);
            }
        }
        
        // Instructions
        this.ctx.font = '18px Courier New';
        this.ctx.textAlign = 'center';
        this.ctx.fillText('Press SPACEBAR to start game', this.width / 2, this.height - 60);
    }
    
    drawInitialsEntry() {
        this.ctx.fillStyle = 'white';
        this.ctx.font = '36px Courier New';
        this.ctx.textAlign = 'center';
        this.ctx.fillText('NEW HIGH SCORE!', this.width / 2, this.height / 2 - 100);
        this.ctx.fillText(`Score: ${this.score}`, this.width / 2, this.height / 2 - 50);
        
        this.ctx.font = '24px Courier New';
        this.ctx.fillText('Enter your initials:', this.width / 2, this.height / 2);
        
        // Draw initials with cursor
        let displayInitials = this.playerInitials.padEnd(3, '_');
        this.ctx.font = '48px Courier New';
        this.ctx.fillText(displayInitials, this.width / 2, this.height / 2 + 50);
        
        // Instructions
        this.ctx.font = '18px Courier New';
        this.ctx.fillText('Use A-Z keys, ENTER to confirm', this.width / 2, this.height / 2 + 120);
    }
    
    handleInitialsInput(e) {
        if (e.code === 'Enter') {
            if (this.playerInitials.length === 3) {
                this.saveHighScore(this.playerInitials, this.score).then(() => {
                    this.gameState = 'showingScores';
                });
            }
            return;
        }
        
        // Handle A-Z keys
        if (e.code.startsWith('Key') && this.playerInitials.length < 3) {
            const letter = e.code.substring(3); // Remove 'Key' prefix
            this.playerInitials += letter;
        }
        
        // Handle backspace
        if (e.code === 'Backspace' && this.playerInitials.length > 0) {
            this.playerInitials = this.playerInitials.slice(0, -1);
        }
    }
    
    resetGame() {
        this.score = 0;
        this.lives = 3;
        this.level = 1;
        this.gameRunning = true;
        this.respawnDelay = 0;
        this.playerInitials = '';
        this.initialsInput = 0;
        
        // Reset game objects
        this.ship = new Ship(this.width / 2, this.height / 2);
        this.asteroids = [];
        this.bullets = [];
        this.particles = [];
        this.ufos = [];
        this.ufoSpawnTimer = 0;
        
        this.initializeLevel();
        this.updateUI();
    }
    
    handleGameOver() {
        this.gameRunning = false;
        this.soundSystem.stopSirenSound();
        
        console.log('Game Over - Score:', this.score);
        console.log('High Scores Count:', this.highScores.length);
        console.log('Is High Score?', this.isHighScore(this.score));
        
        if (this.isHighScore(this.score)) {
            console.log('Entering high score mode');
            this.gameState = 'highScore';
            this.playerInitials = '';
        } else {
            console.log('Not a high score, going to game over screen');
            this.gameState = 'gameOver';
        }
    }
    
    handleTouchStart(e) {
        e.preventDefault();
        console.log('Touch start detected');
        
        const touch = e.touches[0];
        const rect = this.canvas.getBoundingClientRect();
        
        this.touchStartPos = {
            x: touch.clientX - rect.left,
            y: touch.clientY - rect.top
        };
        this.touchCurrentPos = { ...this.touchStartPos };
        this.lastTouchTime = Date.now();
        
        console.log('Touch start at:', this.touchStartPos);
        
        // Start hyperspace timer for tap and hold
        this.hyperspaceTimer = 0;
        this.isHyperspaceHold = true;
        
        // Check if touch is near ship for thrust detection
        const distToShip = this.distanceTo(this.touchStartPos.x, this.touchStartPos.y, this.ship.x, this.ship.y);
        console.log('Distance to ship:', distToShip);
        
        if (distToShip < 50) {
            this.isThrusting = false; // Will be set to true in touchmove if dragging
            this.rotationStartAngle = Math.atan2(this.touchStartPos.y - this.ship.y, this.touchStartPos.x - this.ship.x);
        }
    }
    
    handleTouchMove(e) {
        e.preventDefault();
        if (!this.touchStartPos) return;
        
        console.log('Touch move detected');
        
        const touch = e.touches[0];
        const rect = this.canvas.getBoundingClientRect();
        
        this.touchCurrentPos = {
            x: touch.clientX - rect.left,
            y: touch.clientY - rect.top
        };
        
        // Cancel hyperspace if moving
        this.isHyperspaceHold = false;
        
        const distToShip = this.distanceTo(this.touchStartPos.x, this.touchStartPos.y, this.ship.x, this.ship.y);
        
        if (distToShip < 50) {
            // Touch started near ship
            const dragDistance = this.distanceTo(this.touchStartPos.x, this.touchStartPos.y, this.touchCurrentPos.x, this.touchCurrentPos.y);
            
            if (dragDistance > 15) { // Reduced threshold for easier triggering
                // Check if dragging forward from ship (thrust)
                const dragAngle = Math.atan2(this.touchCurrentPos.y - this.touchStartPos.y, this.touchCurrentPos.x - this.touchStartPos.x);
                const shipAngle = this.ship.angle;
                let angleDiff = Math.abs(dragAngle - shipAngle);
                
                // Normalize angle difference
                if (angleDiff > Math.PI) angleDiff = 2 * Math.PI - angleDiff;
                
                if (angleDiff < Math.PI / 2) { // More lenient thrust detection
                    // Dragging in ship's forward direction
                    this.isThrusting = true;
                    console.log('Thrust activated');
                } else {
                    // Rotating gesture
                    const currentAngle = Math.atan2(this.touchCurrentPos.y - this.ship.y, this.touchCurrentPos.x - this.ship.x);
                    let angleDelta = currentAngle - this.rotationStartAngle;
                    
                    // Normalize angle difference
                    if (angleDelta > Math.PI) angleDelta -= 2 * Math.PI;
                    if (angleDelta < -Math.PI) angleDelta += 2 * Math.PI;
                    
                    // Apply rotation
                    this.ship.rotate(angleDelta * 0.2); // Increased sensitivity
                    this.rotationStartAngle = currentAngle;
                    this.isRotating = true;
                    console.log('Rotation activated');
                }
            }
        }
    }
    
    handleTouchEnd(e) {
        e.preventDefault();
        console.log('Touch end detected');
        
        if (!this.touchStartPos) return;
        
        const touchDuration = Date.now() - this.lastTouchTime;
        const dragDistance = this.touchCurrentPos ? 
            this.distanceTo(this.touchStartPos.x, this.touchStartPos.y, this.touchCurrentPos.x, this.touchCurrentPos.y) : 0;
        
        console.log('Touch duration:', touchDuration, 'Drag distance:', dragDistance, 'Hyperspace timer:', this.hyperspaceTimer);
        
        // Hyperspace (tap and hold for more than 500ms)
        if (this.isHyperspaceHold && this.hyperspaceTimer > 30) { // 30 frames = 500ms at 60fps
            this.ship.hyperspace(this.width, this.height, this.particles);
            this.soundSystem.playHyperspaceSound();
            console.log('Hyperspace activated');
        }
        // Fire (quick tap with minimal movement)
        else if (dragDistance < 15 && touchDuration < 500) { // More lenient tap detection
            if (this.ship.shoot(this.bullets)) {
                this.soundSystem.playShootSound();
                console.log('Shot fired');
            }
        }
        
        // Reset touch state
        this.touchStartPos = null;
        this.touchCurrentPos = null;
        this.isThrusting = false;
        this.isHyperspaceHold = false;
        this.hyperspaceTimer = 0;
        this.isRotating = false;
    }
    
    handleInput() {
        if (this.keys['ArrowLeft']) {
            this.ship.rotate(-0.2);
        }
        if (this.keys['ArrowRight']) {
            this.ship.rotate(0.2);
        }
        if (this.keys['ArrowUp']) {
            this.ship.thrust();
            this.soundSystem.playThrustSound();
        }
        if (this.keys['ArrowDown']) {
            this.ship.hyperspace(this.width, this.height, this.particles);
            this.soundSystem.playHyperspaceSound();
        }
        if (this.keys['Space']) {
            if (this.ship.shoot(this.bullets)) {
                this.soundSystem.playShootSound();
            }
        }
    }
    
    update() {
        if (!this.gameRunning) return;
        
        this.handleInput();
        
        // Update ship
        this.ship.update();
        this.ship.wrapAround(this.width, this.height);
        
        // Update bullets
        this.bullets.forEach((bullet, index) => {
            bullet.update();
            if (bullet.isOffScreen(this.width, this.height)) {
                this.bullets.splice(index, 1);
            }
        });
        
        // Update asteroids
        this.asteroids.forEach(asteroid => {
            asteroid.update();
            asteroid.wrapAround(this.width, this.height);
        });
        
        // Update UFOs
        this.ufos.forEach((ufo, index) => {
            ufo.update();
            if (ufo.isOffScreen(this.width, this.height)) {
                this.ufos.splice(index, 1);
                // Stop siren if no more UFOs
                if (this.ufos.length === 0) {
                    this.soundSystem.stopSirenSound();
                }
            }
        });
        
        // Spawn UFO occasionally (only from level 2 onwards)
        if (this.level >= 2) {
            this.ufoSpawnTimer++;
            if (this.ufoSpawnTimer >= this.ufoSpawnDelay && this.ufos.length === 0) {
                this.spawnUFO();
                this.ufoSpawnTimer = 0;
            }
        }
        
        // Update particles
        this.particles.forEach((particle, index) => {
            particle.update();
            if (particle.life <= 0) {
                this.particles.splice(index, 1);
            }
        });
        
        this.checkCollisions();
        this.updateUI();
    }
    
    spawnUFO() {
        // Spawn UFO from either left or right side
        const side = Math.random() < 0.5 ? 'left' : 'right';
        const x = side === 'left' ? -30 : this.width + 30;
        const y = Math.random() * this.height;
        this.ufos.push(new UFO(x, y, side === 'left' ? 1 : -1));
        this.soundSystem.playUFOSound();
        // Start siren when UFO enters
        this.soundSystem.startSirenSound();
    }
    
    checkCollisions() {
        // Bullet-asteroid collisions
        this.bullets.forEach((bullet, bulletIndex) => {
            this.asteroids.forEach((asteroid, asteroidIndex) => {
                if (this.distanceTo(bullet.x, bullet.y, asteroid.x, asteroid.y) < asteroid.radius) {
                    // Create explosion particles
                    this.createExplosion(asteroid.x, asteroid.y, 'asteroid');
                    
                    // Update score
                    this.score += asteroid.size === 'large' ? 20 : asteroid.size === 'medium' ? 50 : 100;
                    
                    // Break asteroid into smaller pieces
                    if (asteroid.size === 'large') {
                        for (let i = 0; i < 2; i++) {
                            this.asteroids.push(new Asteroid(asteroid.x, asteroid.y, 'medium'));
                        }
                    } else if (asteroid.size === 'medium') {
                        for (let i = 0; i < 2; i++) {
                            this.asteroids.push(new Asteroid(asteroid.x, asteroid.y, 'small'));
                        }
                    }
                    
                    // Remove bullet and asteroid
                    this.bullets.splice(bulletIndex, 1);
                    this.asteroids.splice(asteroidIndex, 1);
                }
            });
        });
        
        // Bullet-UFO collisions
        this.bullets.forEach((bullet, bulletIndex) => {
            this.ufos.forEach((ufo, ufoIndex) => {
                if (this.distanceTo(bullet.x, bullet.y, ufo.x, ufo.y) < 15) {
                    // Create explosion particles
                    this.createExplosion(ufo.x, ufo.y, 'ufo');
                    
                    // Award bonus points for UFO
                    this.score += 500;
                    
                    // Remove bullet and UFO
                    this.bullets.splice(bulletIndex, 1);
                    this.ufos.splice(ufoIndex, 1);
                    
                    // Stop siren if no more UFOs
                    if (this.ufos.length === 0) {
                        this.soundSystem.stopSirenSound();
                    }
                }
            });
        });
        
        // Ship-asteroid collisions
        if (this.respawnDelay <= 0) { // Only check collisions if not in respawn delay
            this.asteroids.forEach(asteroid => {
                if (this.distanceTo(this.ship.x, this.ship.y, asteroid.x, asteroid.y) < asteroid.radius + 10) {
                    this.lives--;
                    this.respawnDelay = this.respawnDelayTime; // Set respawn delay
                    this.createExplosion(this.ship.x, this.ship.y, 'ship');
                    this.ship.reset(this.width / 2, this.height / 2);
                    this.soundSystem.playShipCrashSound();
                    
                    if (this.lives <= 0) {
                        this.handleGameOver();
                    }
                }
            });
            
            // Ship-UFO collisions
            this.ufos.forEach((ufo, ufoIndex) => {
                if (this.distanceTo(this.ship.x, this.ship.y, ufo.x, ufo.y) < ufo.size + 10) {
                    this.lives--;
                    this.respawnDelay = this.respawnDelayTime; // Set respawn delay
                    this.createExplosion(this.ship.x, this.ship.y, 'ship');
                    this.createExplosion(ufo.x, ufo.y, 'ufo'); // UFO also explodes
                    this.ship.reset(this.width / 2, this.height / 2);
                    this.soundSystem.playShipCrashSound();
                    
                    // Remove the UFO that crashed into the ship
                    this.ufos.splice(ufoIndex, 1);
                    
                    // Stop siren if no more UFOs
                    if (this.ufos.length === 0) {
                        this.soundSystem.stopSirenSound();
                    }
                    
                    if (this.lives <= 0) {
                        this.handleGameOver();
                    }
                }
            });
        }
        
        // Update respawn delay
        if (this.respawnDelay > 0) {
            this.respawnDelay--;
        }
        
        // Check if all asteroids destroyed - advance to next level
        if (this.asteroids.length === 0) {
            this.level++;
            this.initializeLevel();
        }
    }
    
    createExplosion(x, y, type = 'default') {
        for (let i = 0; i < 10; i++) {
            this.particles.push(new Particle(x, y));
        }
        
        // Play different sounds based on explosion type
        switch(type) {
            case 'asteroid':
                this.soundSystem.playAsteroidBreakSound();
                break;
            case 'ufo':
                this.soundSystem.playUFOHitSound();
                break;
            case 'ship':
                this.soundSystem.playShipCrashSound();
                break;
            default:
                this.soundSystem.playExplosionSound();
        }
    }
    
    distanceTo(x1, y1, x2, y2) {
        return Math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2);
    }
    
    updateUI() {
        document.getElementById('score').textContent = this.score;
        document.getElementById('lives').textContent = this.lives;
        document.getElementById('level').textContent = this.level;
        
        // Update level display timer
        if (this.showLevelDisplay && this.levelDisplayTimer > 0) {
            this.levelDisplayTimer--;
            if (this.levelDisplayTimer <= 0) {
                this.showLevelDisplay = false;
            }
        }
    }
    
    render() {
        // Clear canvas
        this.ctx.fillStyle = '#000';
        this.ctx.fillRect(0, 0, this.width, this.height);
        
        // Render ship
        this.ship.render(this.ctx);
        
        // Render bullets
        this.bullets.forEach(bullet => bullet.render(this.ctx));
        
        // Render asteroids
        this.asteroids.forEach(asteroid => asteroid.render(this.ctx));
        
        // Render UFOs
        this.ufos.forEach(ufo => ufo.render(this.ctx));
        
        // Render particles
        this.particles.forEach(particle => particle.render(this.ctx));
        
        // Show level display for 1 second at start of each level
        if (this.showLevelDisplay) {
            this.ctx.fillStyle = 'white';
            this.ctx.font = '72px Courier New';
            this.ctx.textAlign = 'center';
            this.ctx.fillText(`LEVEL ${this.level}`, this.width / 2, this.height / 2);
        }
        
        // Show respawn delay countdown
        if (this.respawnDelay > 0) {
            this.ctx.fillStyle = 'yellow';
            this.ctx.font = '24px Courier New';
            this.ctx.textAlign = 'center';
            const seconds = Math.ceil(this.respawnDelay / 60);
            this.ctx.fillText(`Respawning in ${seconds}...`, this.width / 2, this.height / 2 + 100);
        }
        
        // Game over screen
        if (this.gameState === 'gameOver') {
            this.ctx.fillStyle = 'white';
            this.ctx.font = '48px Courier New';
            this.ctx.textAlign = 'center';
            this.ctx.fillText('GAME OVER', this.width / 2, this.height / 2);
            this.ctx.font = '24px Courier New';
            this.ctx.fillText(`Final Score: ${this.score}`, this.width / 2, this.height / 2 + 50);
            this.ctx.fillText('Press SPACEBAR to view high scores', this.width / 2, this.height / 2 + 100);
        }
    }
    
    gameLoop() {
        if (this.gameState === 'showingScores') {
            this.renderHighScores();
        } else if (this.gameState === 'highScore') {
            this.renderInitialsEntry();
        } else {
            this.update();
            this.render();
        }
        requestAnimationFrame(() => this.gameLoop());
    }
    
    renderHighScores() {
        this.ctx.clearRect(0, 0, this.width, this.height);
        this.drawHighScores();
    }
    
    renderInitialsEntry() {
        this.ctx.clearRect(0, 0, this.width, this.height);
        this.drawInitialsEntry();
    }
    
    addMobileToggle() {
        // Add a debug button to manually toggle mobile mode
        if (!this.isMobile) {
            const toggleButton = document.createElement('button');
            toggleButton.textContent = 'Switch to Mobile Mode (Debug)';
            toggleButton.style.position = 'absolute';
            toggleButton.style.top = '10px';
            toggleButton.style.right = '10px';
            toggleButton.style.zIndex = '1000';
            toggleButton.style.padding = '5px 10px';
            toggleButton.style.fontSize = '12px';
            toggleButton.onclick = () => {
                this.isMobile = true;
                this.setupCanvas();
                toggleButton.remove();
                console.log('Manually switched to mobile mode');
            };
            document.body.appendChild(toggleButton);
        }
    }
}

class Ship {
    constructor(x, y) {
        this.x = x;
        this.y = y;
        this.angle = -Math.PI / 2; // Start pointing upward
        this.velocity = { x: 0, y: 0 };
        this.thrustPower = 0.3;
        this.friction = 0.98;
        this.maxSpeed = 8;
        this.shootCooldown = 0;
        this.hyperspaceCooldown = 0;
    }
    
    rotate(angle) {
        this.angle += angle;
    }
    
    thrust() {
        // Apply thrust in the direction the ship is pointing
        this.velocity.x += Math.cos(this.angle) * this.thrustPower;
        this.velocity.y += Math.sin(this.angle) * this.thrustPower;
        
        // Limit speed
        const speed = Math.sqrt(this.velocity.x ** 2 + this.velocity.y ** 2);
        if (speed > this.maxSpeed) {
            this.velocity.x = (this.velocity.x / speed) * this.maxSpeed;
            this.velocity.y = (this.velocity.y / speed) * this.maxSpeed;
        }
    }
    
    shoot(bullets) {
        if (this.shootCooldown <= 0) {
            bullets.push(new Bullet(this.x, this.y, this.angle));
            this.shootCooldown = 10;
            return true; // Return true if bullet was fired
        }
        return false; // Return false if no bullet was fired
    }
    
    hyperspace(width, height, particles) {
        if (this.hyperspaceCooldown <= 0) {
            // Create particles at current position before teleporting
            for (let i = 0; i < 8; i++) {
                particles.push(new Particle(this.x, this.y));
            }
            
            // Teleport to random position
            this.x = Math.random() * width;
            this.y = Math.random() * height;
            
            // Create particles at new position
            for (let i = 0; i < 8; i++) {
                particles.push(new Particle(this.x, this.y));
            }
            
            // Set cooldown to prevent spam (2 seconds at 60fps)
            this.hyperspaceCooldown = 120;
        }
    }
    
    update() {
        this.x += this.velocity.x;
        this.y += this.velocity.y;
        
        this.velocity.x *= this.friction;
        this.velocity.y *= this.friction;
        
        if (this.shootCooldown > 0) {
            this.shootCooldown--;
        }
        
        if (this.hyperspaceCooldown > 0) {
            this.hyperspaceCooldown--;
        }
    }
    
    wrapAround(width, height) {
        if (this.x < 0) this.x = width;
        if (this.x > width) this.x = 0;
        if (this.y < 0) this.y = height;
        if (this.y > height) this.y = 0;
    }
    
    reset(x, y) {
        this.x = x;
        this.y = y;
        this.velocity = { x: 0, y: 0 };
        this.angle = -Math.PI / 2; // Reset to pointing upward
        this.hyperspaceCooldown = 0; // Reset hyperspace cooldown
    }
    
    render(ctx) {
        ctx.save();
        ctx.translate(this.x, this.y);
        ctx.rotate(this.angle);
        
        ctx.strokeStyle = 'white';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(15, 0);
        ctx.lineTo(-10, -8);
        ctx.lineTo(-5, 0);
        ctx.lineTo(-10, 8);
        ctx.closePath();
        ctx.stroke();
        
        ctx.restore();
    }
}

class Bullet {
    constructor(x, y, angle) {
        this.x = x;
        this.y = y;
        this.velocity = {
            x: Math.cos(angle) * 10,
            y: Math.sin(angle) * 10
        };
        this.life = 60; // Bullet lifetime in frames
    }
    
    update() {
        this.x += this.velocity.x;
        this.y += this.velocity.y;
        this.life--;
    }
    
    isOffScreen(width, height) {
        return this.life <= 0 || this.x < 0 || this.x > width || this.y < 0 || this.y > height;
    }
    
    render(ctx) {
        ctx.fillStyle = 'white';
        ctx.beginPath();
        ctx.arc(this.x, this.y, 2, 0, Math.PI * 2);
        ctx.fill();
    }
}

class Asteroid {
    constructor(x, y, size) {
        this.x = x;
        this.y = y;
        this.size = size;
        this.radius = size === 'large' ? 40 : size === 'medium' ? 25 : 15;
        this.velocity = {
            x: (Math.random() - 0.5) * 4,
            y: (Math.random() - 0.5) * 4
        };
        this.rotation = 0;
        this.rotationSpeed = (Math.random() - 0.5) * 0.1;
        
        // Generate random asteroid shape
        this.vertices = [];
        const numVertices = 8;
        for (let i = 0; i < numVertices; i++) {
            const angle = (i / numVertices) * Math.PI * 2;
            const radius = this.radius * (0.8 + Math.random() * 0.4);
            this.vertices.push({
                x: Math.cos(angle) * radius,
                y: Math.sin(angle) * radius
            });
        }
    }
    
    update() {
        this.x += this.velocity.x;
        this.y += this.velocity.y;
        this.rotation += this.rotationSpeed;
    }
    
    wrapAround(width, height) {
        if (this.x < -this.radius) this.x = width + this.radius;
        if (this.x > width + this.radius) this.x = -this.radius;
        if (this.y < -this.radius) this.y = height + this.radius;
        if (this.y > height + this.radius) this.y = -this.radius;
    }
    
    render(ctx) {
        ctx.save();
        ctx.translate(this.x, this.y);
        ctx.rotate(this.rotation);
        
        ctx.strokeStyle = 'white';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(this.vertices[0].x, this.vertices[0].y);
        
        for (let i = 1; i < this.vertices.length; i++) {
            ctx.lineTo(this.vertices[i].x, this.vertices[i].y);
        }
        ctx.closePath();
        ctx.stroke();
        
        ctx.restore();
    }
}

class Particle {
    constructor(x, y) {
        this.x = x;
        this.y = y;
        this.velocity = {
            x: (Math.random() - 0.5) * 6,
            y: (Math.random() - 0.5) * 6
        };
        this.life = 30;
        this.maxLife = 30;
    }
    
    update() {
        this.x += this.velocity.x;
        this.y += this.velocity.y;
        this.velocity.x *= 0.98;
        this.velocity.y *= 0.98;
        this.life--;
    }
    
    render(ctx) {
        const alpha = this.life / this.maxLife;
        ctx.fillStyle = `rgba(255, 255, 255, ${alpha})`;
        ctx.beginPath();
        ctx.arc(this.x, this.y, 1, 0, Math.PI * 2);
        ctx.fill();
    }
}

class UFO {
    constructor(x, y, direction) {
        this.x = x;
        this.y = y;
        this.direction = direction; // 1 for right, -1 for left
        this.speed = 2;
        this.size = 15;
        this.oscillation = 0;
        this.oscillationSpeed = 0.05;
    }
    
    update() {
        this.x += this.direction * this.speed;
        this.oscillation += this.oscillationSpeed;
        this.y += Math.sin(this.oscillation) * 0.5; // Slight vertical movement
    }
    
    isOffScreen(width, height) {
        return this.x < -50 || this.x > width + 50;
    }
    
    render(ctx) {
        ctx.save();
        ctx.translate(this.x, this.y);
        
        ctx.strokeStyle = 'white';
        ctx.fillStyle = 'white';
        ctx.lineWidth = 1;
        
        // Draw UFO body (ellipse)
        ctx.beginPath();
        ctx.ellipse(0, 0, this.size, this.size * 0.4, 0, 0, Math.PI * 2);
        ctx.stroke();
        
        // Draw UFO dome (top half circle)
        ctx.beginPath();
        ctx.arc(0, -3, this.size * 0.6, Math.PI, 0, false);
        ctx.stroke();
        
        // Draw small details (windows)
        ctx.fillStyle = 'white';
        ctx.beginPath();
        ctx.arc(-6, -2, 1, 0, Math.PI * 2);
        ctx.fill();
        ctx.beginPath();
        ctx.arc(0, -2, 1, 0, Math.PI * 2);
        ctx.fill();
        ctx.beginPath();
        ctx.arc(6, -2, 1, 0, Math.PI * 2);
        ctx.fill();
        
        ctx.restore();
    }
}

// Start the game when the page loads
window.addEventListener('load', () => {
    new Game();
});
