const fs = require('fs');

let plants = {};

for (let i = 11; i <= 110; i++) {
  plants[`plant_${String(i).padStart(3, '0')}`] = {
    name: `Sample Plant ${i}`,
    scientificName: `Scientificus plantus ${i}`,
    category: "Indoor",
    difficulty: "Easy",
    waterFrequencyDays: 7,
    sunlight: "Indirect Light",
    temperatureRange: "18-30°C",
    soilType: "Well-draining soil",
    fertilizerFrequencyDays: 30,
    commonProblems: ["Overwatering"],
    careTips: "Water moderately.",
    imageUrl: "",
    isIndianCommon: true
  };
}

fs.writeFileSync('generatedPlants.json', JSON.stringify({ plants }, null, 2));
console.log("100 plants generated.");
