import React, { useState, useEffect } from 'react';

function App() {
    const [data, setData] = useState(null);
    const [error, setError] = useState(null);
    const [loading, setLoading] = useState(true);

    const fetchData = async () => {
        setLoading(true);
        try {
            console.log("Attempting to fetch from http://localhost:8000/data ...");

            // 1. Try to connect
            const res = await fetch('http://localhost:8000/data', {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            // 2. Check if the Server replied with an error (e.g., 500 or 404)
            if (!res.ok) {
                throw new Error(`Server responded with Status Code: ${res.status}`);
            }

            // 3. Parse JSON
            const result = await res.json();
            console.log("Success:", result);
            setData(result);
            setError(null);
        } catch (err) {
            // 4. Catch Network Errors (Server offline, CORS, Port blocked)
            console.error("Fetch Failed:", err);
            setError(err.message);
            setData(null);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
    }, []);

    return (
        <div style={{ fontFamily: 'sans-serif', padding: '40px', textAlign: 'center' }}>
            <h1>Zero Trust Frontend Debugger</h1>

            {/* LOADING STATE */}
            {loading && <h3>🔄 Trying to connect to Backend...</h3>}

            {/* ERROR STATE */}
            {error && (
                <div style={{
                    border: '2px solid red',
                    backgroundColor: '#ffe6e6',
                    padding: '20px',
                    borderRadius: '8px',
                    color: '#d8000c',
                    display: 'inline-block',
                    textAlign: 'left'
                }}>
                    <h3>❌ Connection Failed</h3>
                    <p><strong>Error Message:</strong> {error}</p>
                    <hr style={{ borderColor: 'red' }} />
                    <p><strong>Troubleshooting Steps:</strong></p>
                    <ul style={{ fontSize: '0.9em' }}>
                        <li>Is the Backend container running? (<code>docker ps</code>)</li>
                        <li>Can you open <a href="http://localhost:8000/data" target="_blank" rel="noreferrer">http://localhost:8000/data</a> in a new tab?</li>
                        <li>If the link above works, this is a <strong>CORS</strong> issue.</li>
                        <li>If the link above fails, the Backend is <strong>Crashed</strong> or <strong>Not Port Mapped</strong>.</li>
                    </ul>
                    <button onClick={fetchData} style={{ padding: '10px 20px', cursor: 'pointer' }}>Retry Connection</button>
                </div>
            )}

            {/* SUCCESS STATE */}
            {data && (
                <div style={{
                    border: '2px solid green',
                    backgroundColor: '#e6fffa',
                    padding: '20px',
                    borderRadius: '8px',
                    display: 'inline-block',
                    textAlign: 'left'
                }}>
                    <h3 style={{ color: 'green' }}>✅ Secure Connection Established</h3>
                    <p><strong>Status:</strong> {data.status}</p>
                    <p><strong>DB User:</strong> <code style={{ backgroundColor: '#fff', padding: '4px' }}>{data.db_user}</code></p>
                    <p><strong>Secret Data:</strong> {data.secret_data}</p>
                    <button onClick={fetchData} style={{ marginTop: '10px', padding: '5px 10px', cursor: 'pointer' }}>Refresh Data</button>
                </div>
            )}
        </div>
    );
}

export default App;