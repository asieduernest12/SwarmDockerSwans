import express from 'express';
import { createClient } from 'redis';

const app = express();
const PORT = process.env.PORT || 3001;
const REDIS_HOST = process.env.REDIS_HOST || 'localhost';
const REDIS_PORT = 6379;

const redis = createClient({
	url: `redis://${REDIS_HOST}:${REDIS_PORT}`,
});

redis.on('error', (err) => console.error('Redis Client Error', err));

app.use(express.json());

// Seed data if not present
async function seedCats() {
	const exists = await redis.exists('cats');
	if (!exists) {
		const cats = [
			{ id: '1', name: 'Whiskers', likes: 0 },
			{ id: '2', name: 'Mittens', likes: 0 },
			{ id: '3', name: 'Shadow', likes: 0 },
		];
		for (const cat of cats) {
			await redis.hSet(`cat:${cat.id}`, cat);
			await redis.sAdd('cats', cat.id);
		}
	}
}

app.get('/', async (req, res) => res.send('hello world :'+process.env.HOSTNAME));

app.get('/cats', async (req, res) => {
	const ids = await redis.sMembers('cats');
	const cats = [];
	for (const id of ids) {
		const cat = await redis.hGetAll(`cat:${id}`);
		if (cat.id) {
			cat.likes = Number(cat.likes);
			cats.push(cat);
		}
	}
	res.json(cats);
});

app.post('/cats/:id/like', async (req, res) => {
	const id = req.params.id;
	const exists = await redis.exists(`cat:${id}`);
	if (!exists) return res.status(404).json({ error: 'Cat not found' });
	await redis.hIncrBy(`cat:${id}`, 'likes', 1);
	const cat = await redis.hGetAll(`cat:${id}`);
	cat.likes = Number(cat.likes);
	res.json(cat);
});

redis.connect().then(() => {
	seedCats().then(() => {
		app.listen(PORT, () => {
			console.log(`Express app running on port ${PORT}`);
		});
	});
});
