import path from 'node:path';

export interface RunnerContext {
  runnerTemporaryPath: string;
  githubAction: string;
}

class Action {
  static get supportedPlatforms(): string[] {
    return ['linux', 'win32', 'darwin'];
  }

  static get isRunningLocally(): boolean {
    return process.env.RUNNER_WORKSPACE === undefined;
  }

  static get isRunningFromSource(): boolean {
    return path.basename(__dirname) === 'model';
  }

  static get canonicalName(): string {
    if (Action.isRunningFromSource) {
      return path.basename(path.dirname(path.join(path.dirname(__filename), '/..')));
    }

    return 'unity-builder';
  }

  static get rootFolder(): string {
    if (Action.isRunningFromSource) {
      return path.dirname(path.dirname(path.dirname(__filename)));
    }

    return path.dirname(path.dirname(__filename));
  }

  static get actionFolder(): string {
    return `${Action.rootFolder}/dist`;
  }

  static get workspace(): string {
    return process.env.GITHUB_WORKSPACE!;
  }

  static runnerContext(): RunnerContext {
    const runnerTemporaryPath = process.env.RUNNER_TEMP ?? process.cwd();
    const githubAction = process.env.GITHUB_ACTION ?? process.pid.toString();

    return {
      runnerTemporaryPath,
      githubAction,
    };
  }

  static checkCompatibility() {
    const currentPlatform = process.platform;
    if (!Action.supportedPlatforms.includes(currentPlatform)) {
      throw new Error(`Currently ${currentPlatform}-platform is not supported`);
    }
  }
}

export default Action;
