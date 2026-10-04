import React, { useState } from 'react';

const incidents = [
  {
    title: 'Disk pressure',
    symptom: 'Deployments fail with “No space left on device”.',
    question: 'Which command should you run first?',
    options: ['df -h', 'free -m', 'uptime'],
    answer: 'df -h',
    explanation: 'df -h shows filesystem usage and quickly identifies a full mount.',
  },
  {
    title: 'Service outage',
    symptom: 'The nginx endpoint is down after a configuration change.',
    question: 'What gives the most useful first status report?',
    options: ['systemctl status nginx', 'ps aux | grep ssh', 'whoami'],
    answer: 'systemctl status nginx',
    explanation: 'systemctl reports whether nginx failed and includes recent failure details.',
  },
  {
    title: 'High CPU',
    symptom: 'A VM is slow and its load has suddenly increased.',
    question: 'Which command helps identify the process consuming CPU?',
    options: ['top', 'lsblk', 'ip route'],
    answer: 'top',
    explanation: 'top displays live CPU usage per process and overall system load.',
  },
  {
    title: 'Port unreachable',
    symptom: 'The application should listen on port 8000, but clients cannot connect.',
    question: 'How do you verify that a process is listening on that port?',
    options: ['ss -lntp | grep 8000', 'du -sh /var/log', 'journalctl --vacuum-time=1d'],
    answer: 'ss -lntp | grep 8000',
    explanation: 'ss lists listening TCP sockets and the owning process.',
  },
  {
    title: 'DNS failure',
    symptom: 'The server can reach IP addresses but not domain names.',
    question: 'Which command directly tests DNS resolution?',
    options: ['dig example.com', 'chmod 644 /etc/hosts', 'mount -a'],
    answer: 'dig example.com',
    explanation: 'dig queries DNS and shows the resolver response and timing.',
  },
];

function LinuxTroubleshootingGame() {
  const [step, setStep] = useState(0);
  const [score, setScore] = useState(0);
  const [selected, setSelected] = useState(null);

  const incident = incidents[step];
  const finished = step === incidents.length;

  const choose = (option) => {
    if (selected) return;
    setSelected(option);
    if (option === incident.answer) setScore((current) => current + 1);
  };

  const restart = () => {
    setStep(0);
    setScore(0);
    setSelected(null);
  };

  if (finished) {
    return (
      <main className="container mx-auto px-4 py-12 max-w-2xl text-center">
        <div className="bg-white rounded-2xl shadow-lg p-10">
          <div className="text-5xl mb-4">🐧</div>
          <h1 className="text-3xl font-bold text-gray-900">Incident shift complete</h1>
          <p className="text-xl text-gray-600 mt-4">You resolved {score} of {incidents.length} incidents.</p>
          <button onClick={restart} className="mt-8 bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700">
            Play again
          </button>
        </div>
      </main>
    );
  }

  return (
    <main className="container mx-auto px-4 py-10 max-w-3xl">
      <div className="flex justify-between text-sm text-gray-500 mb-3">
        <span>Linux Incident Lab</span>
        <span>Incident {step + 1}/{incidents.length} · Score {score}</span>
      </div>
      <div className="h-2 bg-gray-200 rounded-full mb-6">
        <div className="h-2 bg-green-500 rounded-full" style={{ width: `${(step / incidents.length) * 100}%` }} />
      </div>
      <section className="bg-gray-900 text-white rounded-2xl shadow-xl overflow-hidden">
        <div className="bg-red-600 px-6 py-3 font-semibold">🚨 {incident.title}</div>
        <div className="p-6 md:p-8">
          <p className="font-mono bg-black rounded-lg p-4 text-green-300 mb-6">{incident.symptom}</p>
          <h1 className="text-2xl font-bold mb-5">{incident.question}</h1>
          <div className="space-y-3">
            {incident.options.map((option) => {
              const correct = selected && option === incident.answer;
              const wrong = selected === option && option !== incident.answer;
              return (
                <button
                  key={option}
                  onClick={() => choose(option)}
                  className={`w-full text-left font-mono p-4 rounded-lg border transition-colors ${
                    correct ? 'bg-green-700 border-green-400' :
                    wrong ? 'bg-red-800 border-red-400' :
                    'bg-gray-800 border-gray-700 hover:border-green-400'
                  }`}
                >
                  $ {option}
                </button>
              );
            })}
          </div>
          {selected && (
            <div className="mt-6">
              <p className={selected === incident.answer ? 'text-green-300' : 'text-red-300'}>
                {selected === incident.answer ? 'Correct.' : `Try this instead: ${incident.answer}`}
              </p>
              <p className="text-gray-300 mt-1">{incident.explanation}</p>
              <button
                onClick={() => { setStep((current) => current + 1); setSelected(null); }}
                className="mt-5 bg-green-600 px-5 py-2 rounded-lg hover:bg-green-700"
              >
                Next incident →
              </button>
            </div>
          )}
        </div>
      </section>
    </main>
  );
}

export default LinuxTroubleshootingGame;
