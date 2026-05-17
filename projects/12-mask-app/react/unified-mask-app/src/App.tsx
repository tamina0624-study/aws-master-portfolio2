import React from 'react';
import './App.css';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import CustomDictionary from './features/CustomDictionary/CustomDictionary.tsx';
import Dashboard from './features/Dashboard/Dashboard.tsx';
import DetectionRules from './features/DetectionRules/DetectionRules.tsx';

function App() {
	return (
		<Router>
			<div className="App">
				<Routes>
					<Route path="/mask-app-react/" element={<Dashboard />} />
					<Route path="/mask-app-react/dashboard" element={<Dashboard />} />
					<Route path="/mask-app-react/custom-dictionary" element={<CustomDictionary />} />
					<Route path="/mask-app-react/detection-rules" element={<DetectionRules />} />
				</Routes>
			</div>
		</Router>
	);
}

export default App;
