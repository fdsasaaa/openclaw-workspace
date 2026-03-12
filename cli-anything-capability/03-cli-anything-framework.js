/**
 * CLI-Anything Framework
 * 将任意软件包装成 Agent-Friendly CLI 的核心框架
 */

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

class CLIAnything {
  constructor() {
    this.tools = new Map();
    this.logs = [];
  }

  /**
   * 注册一个 CLI 工具
   * @param {string} name - 工具名称
   * @param {Object} config - 工具配置
   */
  register(name, config) {
    this.tools.set(name, {
      command: config.command,
      args: config.args || [],
      parser: config.parser || this.defaultParser,
      validator: config.validator || this.defaultValidator,
      description: config.description || '',
      examples: config.examples || []
    });
    console.log(`[CLI-Anything] Registered: ${name}`);
  }

  /**
   * 执行 CLI 命令
   * @param {string} toolName - 工具名称
   * @param {Object} params - 参数对象
   * @returns {Object} 结构化结果
   */
  async execute(toolName, params = {}) {
    const tool = this.tools.get(toolName);
    if (!tool) {
      throw new Error(`Tool not found: ${toolName}`);
    }

    const startTime = Date.now();
    
    try {
      // 构建命令
      const cmd = this.buildCommand(tool, params);
      
      // 执行
      const result = execSync(cmd, {
        encoding: 'utf-8',
        timeout: params.timeout || 30000,
        maxBuffer: 1024 * 1024 * 10 // 10MB
      });

      // 解析输出
      const parsed = tool.parser(result, params);
      
      // 验证结果
      const validated = tool.validator(parsed);

      const execution = {
        tool: toolName,
        params,
        command: cmd,
        success: true,
        result: parsed,
        validated,
        duration: Date.now() - startTime,
        timestamp: new Date().toISOString()
      };

      this.logs.push(execution);
      return execution;

    } catch (error) {
      const execution = {
        tool: toolName,
        params,
        success: false,
        error: error.message,
        stderr: error.stderr?.toString(),
        duration: Date.now() - startTime,
        timestamp: new Date().toISOString()
      };

      this.logs.push(execution);
      return execution;
    }
  }

  /**
   * 构建命令字符串
   */
  buildCommand(tool, params) {
    let cmd = tool.command;
    
    // 替换参数
    for (const [key, value] of Object.entries(params)) {
      if (key === 'timeout') continue;
      cmd = cmd.replace(`{{${key}}}`, value);
    }

    return cmd;
  }

  /**
   * 默认解析器 - 尝试 JSON 解析，否则返回文本
   */
  defaultParser(output) {
    try {
      return JSON.parse(output);
    } catch {
      return { text: output, lines: output.split('\n').filter(l => l.trim()) };
    }
  }

  /**
   * 默认验证器
   */
  defaultValidator(result) {
    return {
      valid: true,
      checks: ['output_exists']
    };
  }

  /**
   * 获取工具列表
   */
  listTools() {
    return Array.from(this.tools.entries()).map(([name, config]) => ({
      name,
      description: config.description,
      examples: config.examples
    }));
  }

  /**
   * 导出日志
   */
  exportLogs(format = 'json') {
    if (format === 'json') {
      return JSON.stringify(this.logs, null, 2);
    }
    return this.logs;
  }
}

// ==================== 预定义工具 ====================

const cli = new CLIAnything();

// 1. 文件信息工具
cli.register('file-info', {
  command: 'powershell -Command "Get-ItemProperty {{path}} | Select-Object Name,Length,LastWriteTime,Extension | ConvertTo-Json"',
  description: '获取文件详细信息',
  examples: [
    { params: { path: 'C:\\file.txt' }, description: '获取文件信息' }
  ],
  parser: (output) => JSON.parse(output)
});

// 2. 图片信息工具 (使用 ImageMagick)
cli.register('image-info', {
  command: 'identify -verbose {{path}}',
  description: '获取图片详细信息',
  examples: [
    { params: { path: 'image.jpg' }, description: '获取图片信息' }
  ],
  parser: (output) => {
    const lines = output.split('\n');
    const info = {};
    lines.forEach(line => {
      if (line.includes(':')) {
        const [key, value] = line.split(':').map(s => s.trim());
        if (key && value) info[key] = value;
      }
    });
    return info;
  }
});

// 3. 图片转换工具
cli.register('image-convert', {
  command: 'convert "{{input}}" {{options}} "{{output}}"',
  description: '转换图片格式或调整大小',
  examples: [
    { params: { input: 'a.jpg', output: 'a.png', options: '' }, description: '格式转换' },
    { params: { input: 'a.jpg', output: 'a-thumb.jpg', options: '-resize 200x200' }, description: '缩略图' }
  ]
});

// 4. 视频信息工具 (使用 ffmpeg)
cli.register('video-info', {
  command: 'ffprobe -v quiet -print_format json -show_format -show_streams "{{path}}"',
  description: '获取视频详细信息',
  examples: [
    { params: { path: 'video.mp4' }, description: '获取视频信息' }
  ],
  parser: (output) => JSON.parse(output)
});

// 5. 视频截图工具
cli.register('video-frame', {
  command: 'ffmpeg -ss {{time}} -i "{{input}}" -vframes 1 -q:v 2 "{{output}}"',
  description: '提取视频指定时间帧',
  examples: [
    { params: { input: 'video.mp4', time: '00:00:10', output: 'frame.jpg' }, description: '提取第10秒帧' }
  ]
});

// 6. PDF 信息工具
cli.register('pdf-info', {
  command: 'powershell -Command "Add-Type -Path \"C:\\Program Files\\WindowsPowerShell\\Modules\\...\"; ..."',
  description: '获取 PDF 信息 (需要额外库)',
  examples: []
});

// 7. 系统信息工具
cli.register('system-info', {
  command: 'powershell -Command "Get-ComputerInfo | Select-Object WindowsVersion, TotalPhysicalMemory, CsProcessors | ConvertTo-Json"',
  description: '获取系统信息',
  parser: (output) => JSON.parse(output)
});

// 8. 目录列表工具
cli.register('dir-list', {
  command: 'powershell -Command "Get-ChildItem {{path}} | Select-Object Name,Length,LastWriteTime,Extension | ConvertTo-Json"',
  description: '列出目录内容',
  parser: (output) => {
    const parsed = JSON.parse(output);
    return Array.isArray(parsed) ? parsed : [parsed];
  }
});

// ==================== 导出 ====================

module.exports = { CLIAnything, cli };

// 如果直接运行，显示帮助
if (require.main === module) {
  console.log('CLI-Anything Framework v1.0');
  console.log('Available tools:', cli.listTools().map(t => t.name).join(', '));
}
