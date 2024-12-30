import express from 'express';
const port = 9000;
const app = express();
import os from 'node:os';

app.get('/service2', (req, res) => {    
    res.send('this is service 2 running on ' + os.hostname());
});

app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});