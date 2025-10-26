#!/usr/bin/env node
// crossword-generator-node.js
// This script uses the actual crossword-layout-generator package

const { generateLayout } = require('crossword-layout-generator');

function generateCrosswordLayout(words) {
  // Convert words to the format expected by the generator
  const inputWords = words.map(word => ({
    clue: word.clue,
    answer: word.answer.toUpperCase()
  }));

  // Use the actual crossword-layout-generator package
  const layout = generateLayout(inputWords);
  
  return layout;
}

// If called directly from command line
if (require.main === module) {
  const encodedJson = process.argv[2];
  const wordsJson = Buffer.from(encodedJson, 'base64').toString('utf8');
  const words = JSON.parse(wordsJson);
  
  // Suppress console output from the package
  const originalConsoleLog = console.log;
  console.log = () => {};
  
  const result = generateCrosswordLayout(words);
  
  // Restore console.log and output only our result
  console.log = originalConsoleLog;
  console.log(JSON.stringify(result));
}
