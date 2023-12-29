
export default class ConsoleProgressUpdater {
  totalProgress: number;
  currentProgress: number;

  constructor (total: number) {
    this.totalProgress = total;
    this.currentProgress = 0;
  }

  next (): void {
    this.currentProgress += 1;

    process.stdout.write('.');
    if (this.currentProgress === this.totalProgress) {
      process.stdout.write(''.padStart(74 - this.currentProgress % 74, ' '));
    }
    if (this.currentProgress % 74 == 0 || this.currentProgress == this.totalProgress) {
      process.stdout.write(`${Math.round(100 * this.currentProgress / this.totalProgress).toString().padStart(4, ' ')}%\n`);
    }
    if (this.currentProgress >= this.totalProgress) {
      process.stdout.write('\n');
    }
  }
}

