import express from 'express';
const port = 8000;
const app = express();
import os from 'node:os';


app.get('/service1', (req, res) => {    
    res.send('this is service 1 running on ' + os.hostname());
});

app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});