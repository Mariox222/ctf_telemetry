-- file content
-- SELECT line, path, sha1, time, size
SELECT *
FROM file_events 
JOIN file_lines 
WHERE file_lines.path = target_path 
AND action = 'UPDATED'
AND atime != mtime
AND time = (SELECT MAX(time) FROM file_events WHERE action = 'UPDATED');


-- shell history
SELECT * 
FROM shell_history 
JOIN users 
ON users.uid = shell_history.uid 
WHERE users.username = 'kali';

-- python packages
SELECT * FROM python_packages JOIN users ON users.uid = python_packages.uid WHERE users.username = 'kali' LIMIT 10;

-- socket events
SELECT * FROM bpf_socket_events;